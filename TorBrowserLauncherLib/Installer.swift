import Cocoa

private func removeQuarantineExtendedAttributes(path: String) throws {
    try Process.run(kXAttrURI, arguments: ["-dr", "com.apple.quarantine", path]).waitUntilExit()
}

public class Installer {
    private var absoluteURI: String
    private var dmgManager: DMGManager
    var statusHandler: (_ s: String) -> Void

    public init(
        absoluteURI: String, dmgManager: DMGManager, statusHandler: @escaping (_ s: String) -> Void
    ) {
        self.absoluteURI = absoluteURI
        self.dmgManager = dmgManager
        self.statusHandler = statusHandler
    }

    public func install(location: URL) throws {
        let basename = (absoluteURI as NSString).lastPathComponent
        let target = location.deletingLastPathComponent().appendingPathComponent(basename)
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        let tbSourceAppDir = (tempDir as NSString).appendingPathComponent(
            kTorBrowserAppBundleBasename)

        // MARK: Write version file
        try basename.write(toFile: kTorBrowserVersionPath, atomically: true, encoding: .ascii)

        // MARK: Place the DMG
        try removeIfExists(url: target)
        try FileManager.default.moveItem(at: location, to: target)

        // MARK: Attach the DMG
        self.statusHandler(
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "download-status-window-mounting-image", tableName: "Lib", value: "Mounting %@",
                    comment: "Displays when the DMG is being attached (mounted)."), basename))
        try self.dmgManager.attach(path: target.path, mountPoint: tempDir)

        // MARK: Remove old Tor Browser.app
        self.statusHandler(
            NSLocalizedString(
                "download-status-window-removing-old-version", tableName: "Lib",
                value: "Removing old version.",
                comment: "Displays when the old version of \"Tor Browser.app\" is being deleted."))
        try removeIfExists(url: kTorBrowserAppURI)

        // MARK: Copy the bundle
        self.statusHandler(
            NSLocalizedString(
                "download-status-window-copying-app-bundle", tableName: "Lib",
                value: "Copying app bundle.",
                comment: "Displays when the \"Tor Browser.app\" is being copied."))
        try FileManager.default.copyItem(atPath: tbSourceAppDir, toPath: kTorBrowserAppPath)

        // MARK: Remove quarantine attributes
        self.statusHandler(
            NSLocalizedString(
                "download-status-window-removing-quarantine-attributes", tableName: "Lib",
                value: "Removing quarantine attributes.",
                comment: """
                    Displays when the com.apple.quarantine extended file attribute is being \
                    removed.
                    """))
        try removeQuarantineExtendedAttributes(path: kTorBrowserAppPath)

        // The DMG will be detached and deleted in DMGManager.deinit().
    }

    /// Check if Tor Browser is installed.
    /// - Returns: true if Tor Browser is installed, false otherwise.
    public class func isInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: kTorBrowserVersionPath)
            && FileManager.default.fileExists(atPath: kTorBrowserAppPath)
    }

    /// Delete the installed copy of Tor Browser.
    public class func uninstall() throws {
        for app in NSWorkspace.shared.runningApplications {
            if let execURL = app.executableURL, execURL.lastPathComponent == "firefox",
                execURL.absoluteString.contains("/Tor%20Browser%20Launcher/")
            {
                app.forceTerminate()
            }
        }
        for url in [kTorBrowserAppURI, kTorBrowserVersionURI] { try removeIfExists(url: url) }
    }

    /// Launch Tor Browser with the given URLs, if any.
    /// - Parameter urls: The URLs to open in Tor Browser, if any.
    public class func launchAndQuit(_ urls: [String]?) throws {
        Task {
            let config = NSWorkspace.OpenConfiguration()
            config.arguments = urls ?? []
            config.addsToRecentItems = false
            try await NSWorkspace.shared.openApplication(
                at: kTorBrowserAppURI, configuration: config)
            delayedQuit(0.2)
        }
    }
}
