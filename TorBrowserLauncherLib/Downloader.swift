import Cocoa

private func findMatchInLines(lines: String, regex: NSRegularExpression) -> String? {
    for line in lines.split(separator: "\n") {
        if let m = regex.firstMatch(
            in: String(line), options: [], range: NSRange(location: 0, length: line.count))
        {
            if m.numberOfRanges > 1 {
                return (String(line) as NSString).substring(with: m.range(at: 1))
            } else {
                return nil
            }
        }
    }
    return nil
}

private func createDownloadSession(delegate: URLSessionDelegate?, proxy: String? = nil)
    -> URLSession
{
    if proxy != nil {
        return backgroundURLSession(
            withProxy: proxy!, identifier: kBackgroundIdentifier, delegate: delegate,
            delegateQueue: OperationQueue())
    }
    return URLSession(
        configuration: URLSessionConfiguration.background(withIdentifier: kBackgroundIdentifier),
        delegate: delegate, delegateQueue: OperationQueue())
}

private func getUpdateIndexContent(session: URLSession) async throws -> (Data, URLResponse) {
    return try await session.data(from: kUpdateIndexURI)
}

private struct Downloads: Codable { var binary: String? }

private func getBinaryURI(session: URLSession, updatePath: String) async throws -> String {
    let url = kUpdateURIPrefix.appendingPathComponent("\(updatePath)/\(kUpdateURISuffix)")
    let (downloadsData, _) = try await session.data(from: url)
    let downloads = try JSONDecoder().decode(Downloads.self, from: downloadsData)
    guard let binary = downloads.binary else {
        throw NSError(
            domain: "tbl", code: 4,
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

private func throwOnStatusCode(_ resp: URLResponse) throws {
    guard let httpResp = resp as? HTTPURLResponse else {
        throw NSError(
            domain: "tbl", code: 8, userInfo: [NSLocalizedDescriptionKey: "Conversion failed."])
    }
    if httpResp.statusCode < 200 || httpResp.statusCode > 299 {
        throw NSError(
            domain: "tbl", code: 7,
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
}

private func findUpdatePath(_ data: Data) throws -> String {
    guard let html = String(data: data, encoding: .utf8),
        let updatePath = findMatchInLines(lines: html, regex: kUpdateRE)
    else {
        throw NSError(
            domain: "tbl", code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Failed to find update path in HTML."])
    }
    return updatePath
}

private func createDirectoryIgnoreError(path: String) {
    try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
}

private func urlSessionWithProxy(_ proxy: String) -> URLSession {
    let spl = proxy.split(separator: ":")
    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.connectionProxyDictionary = [
        kCFNetworkProxiesHTTPEnable as AnyHashable: true,
        kCFNetworkProxiesHTTPPort as AnyHashable: Int(spl.last!, radix: 10)!,
        kCFNetworkProxiesHTTPProxy as AnyHashable: String(spl.first!),
    ]
    return URLSession(configuration: sessionConfiguration)
}

private func backgroundURLSession(
    withProxy proxy: String, identifier: String, delegate: URLSessionDelegate?,
    delegateQueue: OperationQueue?
) -> URLSession {
    let spl = proxy.split(separator: ":")
    let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
    sessionConfiguration.connectionProxyDictionary = [
        kCFNetworkProxiesHTTPEnable as AnyHashable: true,
        kCFNetworkProxiesHTTPPort as AnyHashable: Int(spl.last!, radix: 10)!,
        kCFNetworkProxiesHTTPProxy as AnyHashable: String(spl.first!),
    ]
    return URLSession(
        configuration: sessionConfiguration, delegate: delegate, delegateQueue: delegateQueue)
}

/// Download Tor Browser, optionally using a proxy and a specific mirror.
/// - Parameters:
///   - mirror: The mirror to use, or the default if nil.
///   - proxy: The proxy to use, in the format "host:port", or nil to not use a proxy.
///   - urls: The URLs to open in Tor Browser, if any.
///   - delegate: The URLSessionDelegate to use for download progress.
///   - statusHandler: A callback for status updates.
public func download(
    mirror: String, proxy: String?, urls: [String]?, delegate: URLSessionDelegate,
    statusHandler: @escaping (_ s: String) -> Void
) throws {
    statusHandler(
        NSLocalizedString(
            "download-window-status-label-getting-update-url", tableName: "Lib", value: "Getting update URL",
            comment: "Displayed when the update URL is being generated (first step of the process)."
        ))
    let session = proxy != nil ? urlSessionWithProxy(proxy!) : URLSession.shared

    Task {
        // MARK: Get the updates index
        let (data, resp) = try await getUpdateIndexContent(session: session)
        try throwOnStatusCode(resp)

        // MARK: Find the update path in the HTML
        let updatePath = try findUpdatePath(data)

        // MARK: Create app support directory structure
        statusHandler(
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "download-window-status-creating-app-support-dir", tableName: "Lib", value: "Creating %@",
                    comment: """
                        Displays when a the ~/Library/Application Support/NAME directory \
                        is being created.
                        """), kTorBrowserLauncherPath))
        createDirectoryIgnoreError(path: kTorBrowserLauncherPath)

        // MARK: Download downloads.json
        statusHandler(
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "download-window-status-fetching-filename", tableName: "Lib", value: "Fetching %@",
                    comment: "Displays when a file %@ is being downloaded."), "downloads.json"))
        let binary = try await getBinaryURI(session: session, updatePath: updatePath)

        // MARK: Launch if already installed
        let lastBasename =
            Installer.isInstalled()
            ? (try? String(contentsOfFile: kTorBrowserVersionPath))?.trimmingCharacters(
                in: .whitespacesAndNewlines) : nil
        let basename = (binary as NSString).lastPathComponent
        if lastBasename == basename {
            statusHandler(
                NSLocalizedString(
                    "download-window-status-launching", tableName: "Lib", value: "Launching Tor Browser",
                    comment: "Displayed when Tor Browser is starting."))
            try Installer.launchAndQuit(urls)
        } else {
            // MARK: Download the DMG
            guard let binaryURL = URL(string: binary) else {
                throw NSError(
                    domain: "tbl", code: 5,
                    userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString(
                            "download-window-status-invalid-binary-url", tableName: "Lib",
                            value: "Invalid binary URL. Cannot continue.",
                            comment: "Displayed when the download URL is invalid.")
                    ])
            }
            statusHandler(
                String.localizedStringWithFormat(
                    NSLocalizedString(
                        "download-window-status-fetching-filename", tableName: "Lib", value: "Fetching %@",
                        comment: "Displays when the DMG is being downloaded."), basename))
            createDownloadSession(delegate: delegate, proxy: proxy).downloadTask(with: binaryURL)
                .resume()
        }
    }
}
