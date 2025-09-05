import Cocoa
import TorBrowserLauncherLib

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
        do {
            try download(
                mirror: mirror, proxy: proxy, urls: self.urls, delegate: self,
                statusHandler: self.setStatus)
        } catch { setStatusAndQuit(error.localizedDescription) }
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
        do {
            try Installer(
                absoluteURI: url.absoluteString, dmgManager: DMGManager(),
                statusHandler: self.setStatus
            ).install(location: location)
        } catch {
            setStatusAndQuit(error.localizedDescription)
            return
        }
        self.setStatus(
            NSLocalizedString(
                "download-window-status-launching", value: "Launching Tor Browser.",
                comment: "Displays when Tor Browser is starting."))
        do { try Installer.launchAndQuit(urls) } catch {
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
