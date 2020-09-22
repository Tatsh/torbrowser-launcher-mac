import Cocoa

private let kUpdateURIPrefix = "https://aus1.torproject.org/torbrowser/"
private let kUpdateIndexURI = "https://aus1.torproject.org/torbrowser/?C=M;O=D"
private let kUpdateRE = "a href=\"(update_[^\"]+).*"

private struct Downloads: Codable {
    var downloads: [String: [String: [String: String]]]
    var version: String
}

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

class LauncherWindowController: NSWindow, NSWindowDelegate, URLSessionDelegate,
    URLSessionDownloadDelegate {
    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var statusLabel: NSTextField!

    var urls: [String]?

    private var currentMountedDMGPath: String?
    private var lastBasename: String?

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
    }

    @IBAction func onCancel(_: Any) {
        if currentMountedDMGPath != nil {
            unmount(path: currentMountedDMGPath!)
        }
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }

    func downloadTor() {
        progressBar.doubleValue = 0
        statusLabel.cell?
            .title =
            NSLocalizedString(
                "download-window-status-label-getting-update-url",
                value: "Getting update URL",
                comment: ""
            )

        URLSession.shared
            .dataTask(with: URL(string: kUpdateIndexURI)!) { data, resp, error in
                if error != nil {
                    self
                        .setStatus(
                            String
                                .localizedStringWithFormat(
                                    NSLocalizedString(
                                        "download-window-status-error-fetching-update-index",
                                        value: "Failed to determine update path: (error: %s). Cannot continue.",
                                        comment: ""
                                    ),
                                    error?
                                        .localizedDescription ??
                                        "(no description)"
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
                                    value: "Failed to determine update path (status code %d). Cannot continue.",
                                    comment: ""
                                ),
                                (resp as! HTTPURLResponse).statusCode
                            )
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        NSApp.terminate(nil)
                    }
                    return
                }

                let re = try! NSRegularExpression(pattern: kUpdateRE)
                var updatePath: String?
                for line in String(data: data!, encoding: .utf8)!
                    .split(separator: "\n") {
                    let m = re.firstMatch(
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
                                comment: ""
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
                        comment: ""
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
                                    comment: ""
                                ),
                                "downloads.json"
                            )
                    )
                let downloadsJSON = kUpdateURIPrefix.appending(updatePath!)
                    .appending("release/downloads.json")
                URLSession.shared
                    .dataTask(with: URL(string: downloadsJSON)!) { data, _, error in
                        if error != nil {
                            print(
                                error?
                                    .localizedDescription ??
                                    NSLocalizedString(
                                        "download-window-status-no-error-info",
                                        value: "No error information is available.",
                                        comment: "Displayed when no error details are available."
                                    )
                            )
                            return
                        }
                        let decoder = JSONDecoder()
                        let downloads = try! decoder.decode(
                            Downloads.self,
                            from: data!
                        )
                        let localizedValue = downloads
                            .downloads["osx64"]!["en-US"]
                        let binary = localizedValue!["binary"]!
                        let basename = (binary as NSString).lastPathComponent

                        if self.lastBasename == basename {
                            self
                                .setStatus(
                                    NSLocalizedString(
                                        "download-window-status-launching",
                                        value: "Launching Tor Browser",
                                        comment: "Displayed when Tor Browser is starting."
                                    )
                                )
                            var config =
                                [NSWorkspace.LaunchConfigurationKey: Any]()
                            if self.urls != nil, !self.urls!.isEmpty {
                                config[
                                    NSWorkspace.LaunchConfigurationKey
                                        .arguments
                                ] =
                                    self.urls
                            }
                            try! NSWorkspace.shared
                                .launchApplication(
                                    at: URL(
                                        fileURLWithPath: kTorBrowserAppPath
                                    ),
                                    options: .withoutAddingToRecents,
                                    configuration: config
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
                                                comment: ""
                                            ),
                                            basename
                                        )
                                )
                            let dmgSession =
                                URLSession(
                                    configuration: URLSessionConfiguration
                                        .background(
                                            withIdentifier: "\(Bundle.main.bundleIdentifier!).background"
                                        ),
                                    delegate: self,
                                    delegateQueue: OperationQueue()
                                )
                            dmgSession.downloadTask(with: URL(string: binary)!)
                                .resume()
                        }
                    }.resume()
            }.resume()
    }

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

        try? FileManager.default.removeItem(at: target)
        try! FileManager.default.moveItem(at: location, to: target)

        setStatus(String.localizedStringWithFormat(
            NSLocalizedString(
                "download-status-window-mounting-image",
                value: "Mounting %@",
                comment: ""
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
            comment: ""
        ))
        if FileManager.default.fileExists(atPath: kTorBrowserAppPath) {
            try! FileManager.default
                .removeItem(at: URL(fileURLWithPath: kTorBrowserAppPath))
        }

        setStatus(NSLocalizedString(
            "download-status-window-copying-app-bundle",
            value: "Copying app bundle",
            comment: ""
        ))
        try! FileManager.default.copyItem(
            atPath: tbSourceAppDir,
            toPath: kTorBrowserAppPath
        )

        setStatus(String.localizedStringWithFormat(
            NSLocalizedString(
                "download-status-window-unmounting-image",
                value: "Unmounting %@",
                comment: ""
            ),
            basename
        ))
        unmount(path: tempDir)
        currentMountedDMGPath = nil

        setStatus(NSLocalizedString(
            "download-status-window-removing-quarantine-attributes",
            value: "Removing quarantine attributes",
            comment: ""
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

    private func unmount(path: String) {
        Process.launchedProcess(
            launchPath: "/usr/bin/hdiutil",
            arguments: ["detach", path]
        ).waitUntilExit()
    }

    private func setStatus(_ s: String) {
        DispatchQueue.main.async {
            self.statusLabel.cell?.title = s
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask,
                    didWriteData _: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.progressBar.maxValue = Double(totalBytesExpectedToWrite)
            self.progressBar.doubleValue = Double(totalBytesWritten)
        }
    }
}
