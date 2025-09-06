import Cocoa

/// Binary URI not found in downloads.json.
public let DownloaderNoBinaryURLError = 1
/// Failed to convert URLResponse to HTTPURLResponse.
public let DownloaderConversionFromURLResponseError = 2
/// Failed to determine update path.
public let DownloaderFailedToDetermineUpdatePathError = 3
/// Failed to find update path in HTML.
public let DownloaderFailedToFindUpdatePathError = 4
/// Invalid binary URI.
public let DownloaderInvalidBinaryURIError = 5

private func findMatchInLines(lines: String, regex: NSRegularExpression) throws -> String {
    for line in lines.split(separator: "\n") {
        let m = regex.firstMatch(
            in: String(line), options: [], range: NSRange(location: 0, length: line.count))
        if m != nil && m!.numberOfRanges > 1 {
            return (String(line) as NSString).substring(with: m!.range(at: 1))
        }
    }
    throw NSError(
        domain: "TBLDownloader", code: DownloaderFailedToFindUpdatePathError,
        userInfo: [NSLocalizedDescriptionKey: "Failed to find update path in HTML."])
}

private func getContent(session: URLSession, url: URL) async throws -> (Data, URLResponse) {
    return try await session.data(from: url)
}

private struct Downloads: Codable { var binary: String? }

private func throwOnStatusCode(_ resp: URLResponse) throws {
    #if !TESTING
        guard let httpResp = resp as? HTTPURLResponse else {
            throw NSError(
                domain: "TBLDownloader", code: DownloaderConversionFromURLResponseError,
                userInfo: [NSLocalizedDescriptionKey: "Conversion failed."])
        }
        if httpResp.statusCode < 200 || httpResp.statusCode > 299 {
            throw NSError(
                domain: "TBLDownloader", code: DownloaderFailedToDetermineUpdatePathError,
                userInfo: [
                    NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                        NSLocalizedString(
                            "download-window-status-failed-update-path", tableName: "Lib",
                            value:
                                "Failed to determine update path (status code: %d). Cannot continue.",
                            comment: "Displays when the HTTP status %d is not equal to 200."),
                        httpResp.statusCode)
                ])
        }
    #endif
}

private func findUpdatePath(_ data: Data) throws -> String {
    guard let html = String(data: data, encoding: .utf8) else {
        throw NSError(
            domain: "TBLDownloader", code: DownloaderFailedToFindUpdatePathError,
            userInfo: [NSLocalizedDescriptionKey: "Failed to read HTML content as UTF-8."])
    }
    return try findMatchInLines(lines: html, regex: kUpdateRE)
}

/// Downloader class.
open class Downloader {
    private var delegate: URLSessionDelegate?
    private var fileManager: TBLFileManager
    private var installerType: BaseInstaller.Type
    private var launchCompletionHandler: () -> Void
    private var mirror: String
    private var opener: (_: URL, _: NSWorkspace.OpenConfiguration) throws -> Void
    private var proxy: String?
    private var statusHandler: (_ s: String) -> Void
    private var updateIndexURI: URL
    private var urlSessionFactory: URLSessionFactory
    private var urls: [String]?
    /// Update URI prefix.
    public var updateURIPrefix = kUpdateURIPrefix
    /// Update URI suffix (path).
    public var updateURISuffix = kUpdateURISuffix

    /// Initialiser.
    /// - Parameters:
    ///   - delegate: The URLSession delegate, if any.
    ///   - fileManager: The file manager to use.
    ///   - installerType: The installer type to use.
    ///   - launchCompletionHandler: The completion handler to call when the app is launched.
    ///   - mirror: The mirror to use.
    ///   - opener: The function to use to open URLs.
    ///   - proxy: The proxy to use, if any.
    ///   - statusHandler: The function to use to update the status.
    ///   - updateIndexURI: The update index URI.
    ///   - urlSessionFactory: The URLSession factory to use.
    ///   - urls: The URLs to open after installation, if any.
    public init(
        delegate: URLSessionDelegate?, fileManager: TBLFileManager,
        installerType: BaseInstaller.Type, launchCompletionHandler: @escaping () -> Void,
        mirror: String, opener: @escaping (_: URL, _: NSWorkspace.OpenConfiguration) throws -> Void,
        proxy: String?, statusHandler: @escaping (_ s: String) -> Void, updateIndexURI: URL,
        urlSessionFactory: URLSessionFactory, urls: [String]?
    ) {
        self.delegate = delegate
        self.fileManager = fileManager
        self.installerType = installerType
        self.launchCompletionHandler = launchCompletionHandler
        self.mirror = mirror
        self.opener = opener
        self.proxy = proxy
        self.statusHandler = statusHandler
        self.updateIndexURI = updateIndexURI
        self.urlSessionFactory = urlSessionFactory
        self.urls = urls
    }

    /// Download Tor Browser, optionally using a proxy and a specific mirror.
    /// - Parameters:
    ///   - taskCompletionHandler: An optional completion handler to call when the Task block is
    ///     completed successfully.
    ///   - errorHandler: An optional error handler.
    /// - Throws: An error if the download cannot be started.
    public func download(
        taskCompletionHandler: (() -> Void)? = nil, errorHandler: ((_: Error) -> Void)? = nil
    ) throws {
        statusHandler(
            NSLocalizedString(
                "download-window-status-label-getting-update-url", tableName: "Lib",
                value: "Getting update URL.",
                comment:
                    "Displayed when the update URL is being generated (first step of the process).")
        )
        let session =
            proxy != nil ? urlSessionFactory.urlSessionWithProxy(proxy!) : URLSession.shared
        Task {
            let callErrorHandlerOrThrow: (Error) throws -> Void = { error in
                if let handler = errorHandler { handler(error) } else { throw error }
            }

            // MARK: Get the updates index
            var data: Data = Data()
            do {
                var resp: URLResponse
                (data, resp) = try await getContent(session: session, url: updateIndexURI)
                try throwOnStatusCode(resp)
            } catch {
                #if !TESTING
                    try callErrorHandlerOrThrow(error)
                    return
                #endif
            }

            // MARK: Find the update path in the HTML
            statusHandler(
                NSLocalizedString(
                    "download-window-finding-update-path", tableName: "Lib",
                    value: "Finding update path.",
                    comment: "Displayed when the update path is being found."))
            var updatePath: String
            do { updatePath = try findUpdatePath(data) } catch {
                try callErrorHandlerOrThrow(error)
                return
            }

            // MARK: Create app support directory structure
            statusHandler(
                String.localizedStringWithFormat(
                    NSLocalizedString(
                        "download-window-status-creating-app-support-dir", tableName: "Lib",
                        value: "Creating '%@'.",
                        comment: """
                            Displays when a the ~/Library/Application Support/NAME directory \
                            is being created.
                            """), kTorBrowserLauncherPath))
            do {
                try fileManager.createDirectory(
                    path: kTorBrowserLauncherPath, withIntermediateDirectories: true)
            } catch {
                #if !TESTING
                    try callErrorHandlerOrThrow(error)
                    return
                #endif
            }

            // MARK: Download downloads.json
            statusHandler(
                String.localizedStringWithFormat(
                    NSLocalizedString(
                        "download-window-status-fetching-filename", tableName: "Lib",
                        value: "Fetching %@.",
                        comment: "Displays when a file %@ is being downloaded."), "downloads.json"))
            var binary: String
            do { binary = try await getBinaryURI(session: session, updatePath) } catch {
                try callErrorHandlerOrThrow(error)
                return
            }

            // MARK: Launch if already installed
            let lastBasename =
                installerType.isInstalled()
                ? (try? String(contentsOfFile: kTorBrowserVersionPath))?.trimmingCharacters(
                    in: .whitespacesAndNewlines) : nil
            let basename = (binary as NSString).lastPathComponent
            if lastBasename == basename {
                statusHandler(
                    NSLocalizedString(
                        "download-window-status-launching", tableName: "Lib",
                        value: "Launching Tor Browser.",
                        comment: "Displayed when Tor Browser is starting."))
                do {
                    try installerType.launchAndQuit(urls, opener: opener, launchCompletionHandler)
                } catch { try callErrorHandlerOrThrow(error) }
            } else {
                // MARK: Download the DMG
                guard let binaryURL = URL(string: binary) else {
                    let error = NSError(
                        domain: "TBLDownloader", code: DownloaderInvalidBinaryURIError,
                        userInfo: [
                            NSLocalizedDescriptionKey: NSLocalizedString(
                                "download-window-status-invalid-binary-url", tableName: "Lib",
                                value: "Invalid binary URL. Cannot continue.",
                                comment: "Displayed when the download URL is invalid.")
                        ])
                    try callErrorHandlerOrThrow(error)
                    return
                }
                statusHandler(
                    String.localizedStringWithFormat(
                        NSLocalizedString(
                            "download-window-status-fetching-filename", tableName: "Lib",
                            value: "Fetching %@.",
                            comment: "Displays when the DMG is being downloaded."), basename))
                urlSessionFactory.createDownloadSession(delegate: delegate, proxy: proxy)
                    .downloadTask(with: binaryURL).resume()
                taskCompletionHandler?()
            }
        }
    }

    private func getBinaryURI(session: URLSession, _ updatePath: String) async throws -> String {
        let url = updateURIPrefix.appendingPathComponent("\(updatePath)/\(updateURISuffix)")
        let (downloadsData, _) = try await session.data(from: url)
        let downloads = try JSONDecoder().decode(Downloads.self, from: downloadsData)
        guard let binary = downloads.binary else {
            throw NSError(
                domain: "TBLDownloader", code: DownloaderNoBinaryURLError,
                userInfo: [
                    NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                        NSLocalizedString(
                            "download-window-status-no-binary-url", tableName: "Lib",
                            value: "No binary URL found in downloads.json. Cannot continue.",
                            comment: """
                                Displayed when the downloads.json file does not contain a \
                                binary URL.
                                """))
                ])
        }
        return binary
    }
}
