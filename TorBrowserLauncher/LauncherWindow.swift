import Cocoa

private struct Downloads: Codable { var binary: String? }

// MARK: - Constants

private let kUpdateRE = "a href=\"(update_\\d+[^\"]+).*"
private let kUpdateURIPrefix = "https://aus1.torproject.org/torbrowser/"
private let kUpdateURISuffix = "release/download-macos.json"
private let kUpdateIndexURI = "\(kUpdateURIPrefix)?C=M;O=D"
private let kBackgroundIdentifier = "\(Bundle.main.bundleIdentifier!).background"
private let kTorBrowserAppBundleBasename = "Tor Browser.app"
private let kDefaultMirror = "https://dist.torproject.org/"
private let kAppSupportDirectory = NSSearchPathForDirectoriesInDomains(
    .applicationSupportDirectory, .userDomainMask, true
).first!
let kTorBrowserLauncherPath = (kAppSupportDirectory as NSString).appendingPathComponent(
    "Tor Browser Launcher")
let kTorBrowserAppPath = (kTorBrowserLauncherPath as NSString).appendingPathComponent(
    kTorBrowserAppBundleBasename)
let kTorBrowserVersionPath = (kTorBrowserLauncherPath as NSString).appendingPathComponent("version")

// MARK: -

class LauncherWindowController: NSWindow, NSWindowDelegate, URLSessionDelegate,
    URLSessionDownloadDelegate
{
    // MARK: - Outlets

    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var statusLabel: NSTextField!

    // MARK: - Ivars

    var urls: [String]?
    private var currentMountedDMGPath: String?
    private var lastBasename: String? {
        return FileManager.default.fileExists(atPath: kTorBrowserVersionPath)
            ? try! String(contentsOfFile: kTorBrowserVersionPath).trimmingCharacters(
                in: .whitespacesAndNewlines) : nil
    }

    private var updateRE: NSRegularExpression {
        return try! NSRegularExpression(pattern: kUpdateRE)
    }

    // MARK: - Actions

    @IBAction func onCancel(_: Any) {
        hdiDetach(path: currentMountedDMGPath)
        quit()
    }

    // MARK: - Main download method

    func downloadTor(proxy: String?, mirror: String) {
        progressBar.doubleValue = 0
        setStatus(
            NSLocalizedString(
                "download-window-status-label-getting-update-url", value: "Getting update URL",
                comment:
                    "Displayed when the update URL is being generated (first step of the process).")
        )
        let session = proxy != nil ? urlSessionWithProxy(proxy!) : URLSession.shared

        // MARK: Get the updates index

        Task {
            do {
                // MARK: Get the updates index
                let (data, resp) = try await session.data(from: URL(string: kUpdateIndexURI)!)
                guard let httpResp = resp as? HTTPURLResponse else {
                    self.setStatus("Invalid response")
                    delayedQuit(10)
                    return
                }
                let statusCode = httpResp.statusCode
                if statusCode < 200 || statusCode > 299 {
                    self.setStatus(
                        String.localizedStringWithFormat(
                            NSLocalizedString(
                                "download-window-status-failed-update-path",
                                value:
                                    "Failed to determine update path (status code: %d). Cannot continue.",
                                comment: "Displays when the HTTP status %d is not equal to 200."),
                            statusCode))
                    delayedQuit(10)
                    return
                }

                // MARK: Find the update path in the HTML
                guard let html = String(data: data, encoding: .utf8),
                    let updatePath = findMatchInLines(lines: html, regex: self.updateRE)
                else {
                    self.setStatus(
                        NSLocalizedString(
                            "download-window-status-failed-update-path-2",
                            value: "Failed to determine update path. Cannot continue.",
                            comment:
                                "Displays when the update path (part of a URL) cannot be determined."
                        ))
                    delayedQuit(10)
                    return
                }

                // MARK: Create app support directory structure
                self.setStatus(
                    String.localizedStringWithFormat(
                        NSLocalizedString(
                            "download-window-status-creating-app-support-dir", value: "Creating %@",
                            comment:
                                "Displays when a the ~/Library/Application Support/NAME directory is being created."
                        ), kTorBrowserLauncherPath))
                try? FileManager.default.createDirectory(
                    at: URL(fileURLWithPath: kTorBrowserLauncherPath),
                    withIntermediateDirectories: false, attributes: nil)

                // MARK: Download downloads.json
                self.setStatus(
                    String.localizedStringWithFormat(
                        NSLocalizedString(
                            "download-window-status-fetching-filename", value: "Fetching %@",
                            comment: "Displays when a file %@ is being downloaded."),
                        "downloads.json"))
                let url = URL(
                    string: kUpdateURIPrefix.appending(updatePath).appending(kUpdateURISuffix))!
                let (downloadsData, _) = try await session.data(from: url)
                let downloads = try JSONDecoder().decode(Downloads.self, from: downloadsData)
                guard let binary = downloads.binary else {
                    self.setStatus(
                        NSLocalizedString(
                            "download-window-no-url-found", value: "Failed to get a URL",
                            comment: "Displayed when a download URL for Tor Browser cannot be found"
                        ))
                    delayedQuit(2)
                    return
                }

                // MARK: Launch if already installed
                let basename = (binary as NSString).lastPathComponent
                if self.lastBasename == basename,
                    FileManager.default.fileExists(atPath: kTorBrowserAppPath)
                {
                    self.setStatus(
                        NSLocalizedString(
                            "download-window-status-launching", value: "Launching Tor Browser",
                            comment: "Displayed when Tor Browser is starting."))
                    launchTorBrowser(self.urls)
                    delayedQuit(0.2)
                } else {
                    // MARK: Download the DMG
                    self.setStatus(
                        String.localizedStringWithFormat(
                            NSLocalizedString(
                                "download-window-status-fetching-filename", value: "Fetching %@",
                                comment: "Displays when the DMG is being downloaded."), basename))
                    let downloadSession: URLSession
                    if proxy != nil {
                        downloadSession = backgroundURLSession(
                            withProxy: proxy!, identifier: kBackgroundIdentifier, delegate: self,
                            delegateQueue: OperationQueue())
                    } else {
                        downloadSession = URLSession(
                            configuration: URLSessionConfiguration.background(
                                withIdentifier: kBackgroundIdentifier), delegate: self,
                            delegateQueue: OperationQueue())
                    }
                    downloadSession.downloadTask(with: URL(string: binary)!).resume()
                }
            } catch {
                self.setStatus(
                    String.localizedStringWithFormat(
                        NSLocalizedString(
                            "download-window-status-error-fetching-update-index",
                            value: "Failed to determine update path: (error: %s). Cannot continue.",
                            comment:
                                "Displayed when the update URL cannot be determined (likely because the site is down)."
                        ), error.localizedDescription))
                delayedQuit(10)
            }
        }
    }

    // MARK: - URL session delegate

    func urlSession(
        _: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL
    ) {
        let absoluteStr = ((downloadTask.currentRequest?.url!.absoluteString)! as NSString)
        let basename = absoluteStr.lastPathComponent
        let target = location.deletingLastPathComponent().appendingPathComponent(basename)
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        let tbSourceAppDir = (tempDir as NSString).appendingPathComponent(
            kTorBrowserAppBundleBasename)

        // MARK: Write version file

        try! basename.write(toFile: kTorBrowserVersionPath, atomically: true, encoding: .ascii)

        // MARK: Place the DMG

        removeIfExists(path: target.path)
        try! FileManager.default.moveItem(at: location, to: target)

        // MARK: Attach the DMG

        setStatus(
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "download-status-window-mounting-image", value: "Mounting %@",
                    comment: "Displays when the DMG is being attached (mounted)."), basename))
        hdiAttach(path: target.path, mountPoint: tempDir)
        currentMountedDMGPath = tempDir

        // MARK: Remove old Tor Browser.app

        setStatus(
            NSLocalizedString(
                "download-status-window-removing-old-version", value: "Removing old version",
                comment: "Displays when the old version of \"Tor Browser.app\" is being deleted."))
        removeIfExists(path: kTorBrowserAppPath)

        // MARK: Copy the bundle

        setStatus(
            NSLocalizedString(
                "download-status-window-copying-app-bundle", value: "Copying app bundle",
                comment: "Displays when the \"Tor Browser.app\" is being copied."))
        try! FileManager.default.copyItem(atPath: tbSourceAppDir, toPath: kTorBrowserAppPath)

        // MARK: Detach the DMG

        setStatus(
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "download-status-window-unmounting-image", value: "Unmounting %@",
                    comment: "Displays when the DMG is being detached (unmounted)."), basename))
        hdiDetach(path: tempDir)
        currentMountedDMGPath = nil

        // MARK: Remove quarantine attributes

        setStatus(
            NSLocalizedString(
                "download-status-window-removing-quarantine-attributes",
                value: "Removing quarantine attributes",
                comment:
                    "Displays when the com.apple.quarantine extended file attribute is being removed."
            ))
        removeQuarantineExtendedAttributes(path: kTorBrowserAppPath)

        // MARK: Launch

        setStatus(
            NSLocalizedString(
                "download-window-status-launching", value: "Launching Tor Browser",
                comment: "Displayed when Tor Browser is starting"))
        launchTorBrowser(urls)
        quit()
    }

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

    /// Set the status label text.
    private func setStatus(_ s: String) {
        DispatchQueue.main.async { self.statusLabel.cell?.title = s }
    }
}
