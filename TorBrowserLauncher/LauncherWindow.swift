import Cocoa
import Combine
import TorBrowserLauncherLib

/// File manager implementation using Foundation's FileManager.
class TBLNSFileManager: TBLFileManager {
    private let kXAttrURI = URL(fileURLWithPath: "/usr/bin/xattr")

    func copyItem(atPath: String, toPath: String) throws {
        try FileManager.default.copyItem(atPath: atPath, toPath: toPath)
    }

    func createDirectory(path: String, withIntermediateDirectories intermediate: Bool) throws {
        try FileManager.default.createDirectory(
            atPath: path, withIntermediateDirectories: intermediate)
    }

    func createDirectoryIgnoreError(
        path: String, withIntermediateDirectories intermediate: Bool = true
    ) {
        try? FileManager.default.createDirectory(
            atPath: path, withIntermediateDirectories: intermediate)
    }

    func fileExists(atPath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    func moveItem(at: URL, to: URL) throws { try FileManager.default.moveItem(at: at, to: to) }

    func removeIfExists(url: URL) throws {
        if fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    func removeQuarantineExtendedAttribute(path: String) throws {
        try Process.run(kXAttrURI, arguments: ["-dr", "com.apple.quarantine", path]).waitUntilExit()
    }

    func temporaryDirectory() -> String {
        return (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
    }

    func writeContent(content: String, toPath path: String) throws {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

/// Installer implementation that terminates and removes Tor Browser.
class Installer: BaseInstaller {
    private static var cancellable: Cancellable?

    public class func uninstall(fileManager: TBLFileManager, completionHandler: (() -> Void)? = nil)
        throws
    {
        let callCompletionHandler = {
            try? fileManager.removeIfExists(url: kTorBrowserAppURI)
            try? fileManager.removeIfExists(url: kTorBrowserVersionURI)
            completionHandler?()
        }
        for app in NSWorkspace.shared.runningApplications {
            if let execURL = app.executableURL, execURL.lastPathComponent == "firefox",
                execURL.absoluteString.contains("/Tor%20Browser%20Launcher/") {
                cancellable = app.publisher(for: \.isTerminated).sink { isTerminated in
                    if isTerminated {
                        callCompletionHandler()
                    }
                }
                app.terminate()
                return
            }
        }
        callCompletionHandler()
    }
}

/// The launcher window controller, which handles downloading and installing Tor Browser.
class LauncherWindowController: NSWindow, NSWindowDelegate, URLSessionDelegate,
    URLSessionDownloadDelegate
{
    // MARK: - Outlets
    /// Progress bar showing download progress.
    @IBOutlet var progressBar: NSProgressIndicator!
    /// Status label showing current status.
    @IBOutlet var statusLabel: NSTextField!

    // MARK: - Ivars
    /// URLs to open with Tor Browser.
    var urls: [String]?

    // MARK: - Actions

    /// On cancel, detach any mounted DMG and quit.
    /// Parameter _: The sender.
    @IBAction func onCancel(_: Any) { quit() }

    class func setup() -> LauncherWindowController {
        let vc = LauncherWindowController()
        Bundle.main.loadNibNamed(NSNib.Name("LauncherWindow"), owner: vc, topLevelObjects: nil)
        vc.urls = getFilteredCommandLineArguments()
        return vc
    }

    // MARK: - Main download method

    /// Download Tor Browser, optionally using a proxy and a specific mirror.
    /// - Parameters:
    ///   - mirror: The mirror to use, or the default if nil.
    ///   - proxy: The proxy to use, in the format "host:port", or nil to not use a proxy.
    func start(mirror: String, proxy: String?) {
        progressBar.doubleValue = 0
        let downloader = Downloader(
            delegate: self, fileManager: TBLNSFileManager(), installerType: Installer.self,
            launchCompletionHandler: { delayedQuit(0.2) }, mirror: mirror,
            opener: { appURL, config in
                DispatchQueue.main.async {
                    NSWorkspace.shared.openApplication(at: appURL, configuration: config)
                }
            }, proxy: proxy, statusHandler: self.setStatus, updateIndexURI: kUpdateIndexURI,
            urlSessionFactory: TBLURLSessionFactory(), urls: self.urls)
        do { try downloader.download() } catch { setStatusAndQuit(error.localizedDescription) }
    }

    // MARK: - URL session delegate

    /// On completion of download, mount the DMG, copy the app bundle, unmount the DMG, remove
    /// quarantine attributes, and launch Tor Browser.
    /// - Parameters:
    ///   - _: The URL session.
    ///   - downloadTask: The download task.
    ///   - location: The temporary file URL where the downloaded file is located.
    func urlSession(
        _: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL
    ) {
        guard let url = downloadTask.currentRequest?.url else {
            setStatusAndQuit(
                NSLocalizedString(
                    "launcher-status-error", value: "Error: download URL is nil",
                    comment: "Displays when the download URL is nil."))
            return
        }
        let installer = Installer(
            absoluteURI: url.absoluteString, dmgManager: DMGManager(),
            fileManager: TBLNSFileManager(), statusHandler: self.setStatus
        )
        do { try installer.install(location: location)
        } catch {
            setStatusAndQuit(error.localizedDescription)
            return
        }
        self.setStatus(
            NSLocalizedString(
                "download-window-status-launching", value: "Launching Tor Browser.",
                comment: "Displays when Tor Browser is starting."))
        do {
            try Installer.launchAndQuit(
                urls,
                opener: { appURL, config in
                    DispatchQueue.main.async {
                        NSWorkspace.shared.openApplication(at: appURL, configuration: config)
                    }
                }
            ) { delayedQuit(0.2) }
        } catch {
            setStatusAndQuit(
                String(
                    format: NSLocalizedString(
                        "launcher-status-launch-error", value: "Launch error: %@",
                        comment: "Displays when there is an error launching Tor Browser."),
                    error.localizedDescription))
        }
    }

    /// Update the progress bar as data is written.
    /// - Parameters:
    ///   - _: The URL session.
    ///   - downloadTask: The download task.
    ///   - bytesWritten: The number of bytes written since the last call.
    ///   - totalBytesWritten: The total number of bytes written so far.
    ///   - totalBytesExpectedToWrite: The total number of bytes expected to be written.
    func urlSession(
        _: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64,
        totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        // MARK: Update the progress bar
        DispatchQueue.main.async {
            self.progressBar.doubleValue = Double(totalBytesWritten)
            self.progressBar.maxValue = Double(totalBytesExpectedToWrite)
        }
    }

    // MARK: - Private

    private func setStatus(_ s: String) {
        DispatchQueue.main.async { self.statusLabel.cell?.title = s }
    }

    private func setStatusAndQuit(_ s: String, _ waitTime: Double = 10) {
        setStatus(s)
        delayedQuit(waitTime)
    }

    private func quit() { DispatchQueue.main.async { NSApp.terminate(nil) } }
}

private func getFilteredCommandLineArguments() -> [String] {
    var args = Array(CommandLine.arguments[1...])
    if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
        args = args.filter {
            !$0.starts(with: "-") && $0.lowercased() != "yes" && $0.lowercased() != "no"
                && !$0.hasPrefix("(")
        }
    }
    return args
}

/// URL session factory implementation.
private class TBLURLSessionFactory: URLSessionFactory {
    func createDownloadSession(delegate: URLSessionDelegate?, proxy: String? = nil) -> URLSession {
        if proxy != nil {
            return backgroundURLSession(
                withProxy: proxy!, identifier: kBackgroundIdentifier, delegate: delegate,
                delegateQueue: OperationQueue())
        }
        return URLSession(
            configuration: URLSessionConfiguration.background(
                withIdentifier: kBackgroundIdentifier), delegate: delegate,
            delegateQueue: OperationQueue())
    }

    func urlSessionWithProxy(_ proxy: String) -> URLSession {
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
}
