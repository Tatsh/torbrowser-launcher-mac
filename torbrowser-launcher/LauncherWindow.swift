import Cocoa

private struct Downloads: Codable {
    var downloads: [String: [String: [String: String]]]
    var version: String
}

// MARK: - Constants

private let kUpdateRE = "a href=\"(update_[^\"]+).*"
private let kUpdateURIPrefix = "https://aus1.torproject.org/torbrowser/"
private let kUpdateIndexURI = "\(kUpdateURIPrefix)?C=M;O=D"

private let kAppSupportDirectory = NSSearchPathForDirectoriesInDomains(
    .applicationSupportDirectory,
    .userDomainMask,
    true
).first!
let kTorBrowserLauncherPath = (kAppSupportDirectory as NSString)
    .appendingPathComponent("Tor Browser Launcher")
let kTorBrowserAppPath = (kTorBrowserLauncherPath as NSString)
    .appendingPathComponent("Tor Browser.app")
let kTorBrowserVersionPath = (kTorBrowserLauncherPath as NSString)
    .appendingPathComponent("version")

// MARK: -

class LauncherWindowController: NSWindow, NSWindowDelegate, URLSessionDelegate,
    URLSessionDownloadDelegate {
    // MARK: - Outlets

    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var statusLabel: NSTextField!

    // MARK: - Ivars

    var urls: [String]?

    private var currentMountedDMGPath: String?
    private var hasSetMaxValue = false
    private var lastBasename: String?
    private var updateRE: NSRegularExpression?

    // MARK: - Initializers

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
        if FileManager.default.fileExists(atPath: kTorBrowserVersionPath) {
            lastBasename = try! String(contentsOfFile: kTorBrowserVersionPath)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        updateRE = try! NSRegularExpression(pattern: kUpdateRE)
    }

    // MARK: - Actions

    @IBAction func onCancel(_: Any) {
        if currentMountedDMGPath != nil {
            unmount(path: currentMountedDMGPath!)
        }
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }

    // MARK: - Utility

    func downloadTor(proxy: String?) {
        progressBar.doubleValue = 0
        statusLabel.cell?
            .title =
            NSLocalizedString(
                "download-window-status-label-getting-update-url",
                value: "Getting update URL",
                comment: "Displayed when the update URL is being generated (first step of the process)."
            )

        var session = URLSession.shared
        if proxy != nil {
            let sessionConfiguration = URLSessionConfiguration.default
            let spl = proxy!.split(separator: ":")
            sessionConfiguration.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable as AnyHashable: true,
                kCFNetworkProxiesHTTPPort as AnyHashable: Int(spl.last!)!,
                kCFNetworkProxiesHTTPProxy as AnyHashable: spl.first!
            ]
            session = URLSession(configuration: sessionConfiguration)
        }

        session
            .dataTask(with: URL(string: kUpdateIndexURI)!) { data, resp, error in
                if error != nil {
                    self
                        .setStatus(
                            String
                                .localizedStringWithFormat(
                                    NSLocalizedString(
                                        "download-window-status-error-fetching-update-index",
                                        value: "Failed to determine update path: (error: %s). Cannot continue.",
                                        comment: "Displayed when the update URL cannot be determined (likely because the site is down)."
                                    ),
                                    error?
                                        .localizedDescription ??
                                        NSLocalizedString(
                                            "download-window-status-error-no-description",
                                            value: "(no description)",
                                            comment: "Generic \"no description\" text."
                                        )
                                )
                        )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        NSApp.terminate(nil)
                    }
                    return
                }

                if (resp as! HTTPURLResponse)
                    .statusCode < 200 || (resp as! HTTPURLResponse)
                    .statusCode > 299 {
                    DispatchQueue.main.async {
                        self.statusLabel.cell?.title = String
                            .localizedStringWithFormat(
                                NSLocalizedString(
                                    "download-window-status-failed-update-path",
                                    value: "Failed to determine update path (status code: %d). Cannot continue.",
                                    comment: "Displays when the HTTP status %d is not equal to 200."
                                ),
                                (resp as! HTTPURLResponse).statusCode
                            )
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        NSApp.terminate(nil)
                    }
                    return
                }

                var updatePath: String?
                for line in String(data: data!, encoding: .utf8)!
                    .split(separator: "\n") {
                    let m = self.updateRE!.firstMatch(
                        in: String(line),
                        options: [],
                        range: NSRange(
                            location: 0,
                            length: line.count
                        )
                    )
                    if m == nil {
                        continue
                    }
                    updatePath = (String(line) as NSString)
                        .substring(with: m!.range(at: 1))
                    break
                }
                if updatePath == nil {
                    self
                        .setStatus(
                            NSLocalizedString(
                                "download-window-status-failed-update-path-2",
                                value: "Failed to determine update path. Cannot continue.",
                                comment: "Displays when the update path (part of a URL) cannot be determined."
                            )
                        )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        NSApp.terminate(nil)
                    }
                    return
                }

                self.setStatus(String.localizedStringWithFormat(
                    NSLocalizedString(
                        "download-window-status-creating-app-support-dir",
                        value: "Creating %@",
                        comment: "Displays when a the ~/Library/Application Support/NAME directory is being created."
                    ),
                    kTorBrowserLauncherPath
                ))

                try? FileManager.default
                    .createDirectory(
                        at: URL(
                            fileURLWithPath: kTorBrowserLauncherPath
                        ),
                        withIntermediateDirectories: false,
                        attributes: nil
                    )

                self
                    .setStatus(
                        String
                            .localizedStringWithFormat(
                                NSLocalizedString(
                                    "download-window-status-fetching-filename",
                                    value: "Fetching %@",
                                    comment: "Displays when a file %@ is being downloaded."
                                ),
                                "downloads.json"
                            )
                    )
                session
                    .dataTask(with: URL(
                        string: kUpdateURIPrefix
                            .appending(updatePath!)
                            .appending(
                                "release/downloads.json"
                            )
                    )!) { data, _, error in
                        if error != nil {
                            print(
                                error?
                                    .localizedDescription ??
                                    NSLocalizedString(
                                        "download-window-status-error-no-description",
                                        value: "(no description)",
                                        comment: ""
                                    )
                            )
                            return
                        }
                        let downloads = try! JSONDecoder().decode(
                            Downloads.self,
                            from: data!
                        )
                        let binary = downloads
                            .downloads["osx64"]!["en-US"]!["binary"]!
                        let basename = (binary as NSString)
                            .lastPathComponent

                        if self.lastBasename == basename,
                            FileManager.default
                            .fileExists(atPath: kTorBrowserAppPath) {
                            self
                                .setStatus(
                                    NSLocalizedString(
                                        "download-window-status-launching",
                                        value: "Launching Tor Browser",
                                        comment: "Displayed when Tor Browser is starting."
                                    )
                                )
                            try! NSWorkspace.shared
                                .launchApplication(
                                    at: URL(
                                        fileURLWithPath: kTorBrowserAppPath
                                    ),
                                    options: .withoutAddingToRecents,
                                    configuration: [
                                        NSWorkspace
                                            .LaunchConfigurationKey
                                            .arguments: self
                                            .urls != nil ? self
                                            .urls ?? [] : [],
                                    ]
                                )
                            DispatchQueue.main
                                .asyncAfter(deadline: .now() + 0.2) {
                                    NSApp.terminate(nil)
                                }
                        } else {
                            // TODO: Implement signature checking with GPG
                            // let sig = localizedValue!["sig"]!
                            self
                                .setStatus(
                                    String
                                        .localizedStringWithFormat(
                                            NSLocalizedString(
                                                "download-window-status-fetching-filename",
                                                value: "Fetching %@",
                                                comment: "Displays when the DMG is being downloaded."
                                            ),
                                            basename
                                        )
                                )
                            let config = URLSessionConfiguration
                                .background(
                                    withIdentifier: "\(Bundle.main.bundleIdentifier!).background"
                                )
                            if proxy != nil {
                                let spl = proxy!.split(separator: ":")
                                config.connectionProxyDictionary = [
                                    kCFNetworkProxiesHTTPEnable as AnyHashable: true,
                                    kCFNetworkProxiesHTTPPort as AnyHashable: Int(spl.last!)!,
                                    kCFNetworkProxiesHTTPProxy as AnyHashable: spl.first!
                                ]
                            }
                            URLSession(
                                configuration: URLSessionConfiguration
                                    .background(
                                        withIdentifier: "\(Bundle.main.bundleIdentifier!).background"
                                    ),
                                delegate: self,
                                delegateQueue: OperationQueue()
                            ).downloadTask(with: URL(string: binary)!)
                                .resume()
                        }
                    }.resume()
            }.resume()
    }

    // MARK: - URL session delegate

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let basename =
            ((downloadTask.currentRequest?.url!.absoluteString)! as NSString)
                .lastPathComponent
        let target = location.deletingLastPathComponent()
            .appendingPathComponent(basename)
        let tempDir = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent(ProcessInfo().globallyUniqueString)
        let tbSourceAppDir = (tempDir as NSString)
            .appendingPathComponent("Tor Browser.app")
        try! basename.write(
            toFile: kTorBrowserVersionPath,
            atomically: true,
            encoding: .ascii
        )

        if FileManager.default.fileExists(atPath: target.path) {
            try! FileManager.default.removeItem(at: target)
        }
        try! FileManager.default.moveItem(at: location, to: target)

        setStatus(String.localizedStringWithFormat(
            NSLocalizedString(
                "download-status-window-mounting-image",
                value: "Mounting %@",
                comment: "Displays when the DMG is being attached (mounted)."
            ),
            basename
        ))
        Process.launchedProcess(
            launchPath: "/usr/bin/hdiutil",
            arguments: [
                "attach",
                target.path,
                "-mountpoint",
                tempDir,
                "-private",
                "-nobrowse",
                "-noautoopen",
                "-noautofsck",
                "-noverify",
                "-readonly",
            ]
        ).waitUntilExit()
        currentMountedDMGPath = tempDir

        setStatus(NSLocalizedString(
            "download-status-window-removing-old-version",
            value: "Removing old version",
            comment: "Displays when the old version of \"Tor Browser.app\" is being deleted."
        ))
        if FileManager.default.fileExists(atPath: kTorBrowserAppPath) {
            try! FileManager.default
                .removeItem(at: URL(fileURLWithPath: kTorBrowserAppPath))
        }

        setStatus(NSLocalizedString(
            "download-status-window-copying-app-bundle",
            value: "Copying app bundle",
            comment: "Displays when the \"Tor Browser.app\" is being copied."
        ))
        try! FileManager.default.copyItem(
            atPath: tbSourceAppDir,
            toPath: kTorBrowserAppPath
        )

        setStatus(String.localizedStringWithFormat(
            NSLocalizedString(
                "download-status-window-unmounting-image",
                value: "Unmounting %@",
                comment: "Displays when the DMG is being detached (unmounted)."
            ),
            basename
        ))
        unmount(path: tempDir)
        currentMountedDMGPath = nil

        setStatus(NSLocalizedString(
            "download-status-window-removing-quarantine-attributes",
            value: "Removing quarantine attributes",
            comment: "Displays when the com.apple.quarantine extended file attribute is being removed."
        ))
        Process.launchedProcess(
            launchPath: "/usr/bin/xattr",
            arguments: [
                "-dr",
                "com.apple.quarantine",
                kTorBrowserAppPath,
            ]
        ).waitUntilExit()

        setStatus(NSLocalizedString(
            "download-window-status-launching",
            value: "Launching Tor Browser",
            comment: "Displayed when Tor Browser is starting"
        ))
        var config = [NSWorkspace.LaunchConfigurationKey: Any]()
        if urls != nil, !urls!.isEmpty {
            config[NSWorkspace.LaunchConfigurationKey.arguments] = urls
        }
        try! NSWorkspace.shared
            .launchApplication(
                at: URL(fileURLWithPath: kTorBrowserAppPath),
                options: .withoutAddingToRecents,
                configuration: config
            )

        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask,
                    didWriteData _: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if !hasSetMaxValue {
            DispatchQueue.main.async {
                self.progressBar.maxValue = Double(totalBytesExpectedToWrite)
            }
            hasSetMaxValue = true
        }
        DispatchQueue.main.async {
            self.progressBar.doubleValue = Double(totalBytesWritten)
        }
    }

    // MARK: - Private

    private func setStatus(_ s: String) {
        DispatchQueue.main.async {
            self.statusLabel.cell?.title = s
        }
    }

    private func unmount(path: String) {
        Process.launchedProcess(
            launchPath: "/usr/bin/hdiutil",
            arguments: ["detach", path]
        ).waitUntilExit()
    }
}
