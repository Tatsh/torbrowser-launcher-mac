import Cocoa

/// Do not use directly except in tests.
public protocol BaseInstallerProtocol {
    /// Uninstall Tor Browser.
    /// - Parameters:
    ///   - fileManager: File manager.
    ///   - completionHandler: Completion handler.
    static func uninstall(fileManager: TBLFileManager, completionHandler: (() -> Void)?) throws
}

/// Do not use directly except in tests.
open class _BaseInstaller {
    private var absoluteURI: String
    private var dmgManager: DMGManager
    private var fileManager: TBLFileManager
    private var statusHandler: (_ s: String) -> Void

    /// Initialiser.
    /// - Parameters:
    ///   - absoluteURI: The absolute URI of the DMG to install.
    ///   - dmgManager: The DMG manager to use.
    ///   - fileManager: File manager.
    ///   - statusHandler: Status callback.
    public init(
        absoluteURI: String, dmgManager: DMGManager, fileManager: TBLFileManager,
        statusHandler: @escaping (_ s: String) -> Void
    ) {
        self.absoluteURI = absoluteURI
        self.dmgManager = dmgManager
        self.fileManager = fileManager
        self.statusHandler = statusHandler
    }

    /// Install Tor Browser from the given DMG location.
    /// - Parameters:
    ///   - location: The location of the DMG file.
    /// - Throws: An error if the installation fails.
    public func install(location: URL) throws {
        let basename = (absoluteURI as NSString).lastPathComponent
        let target = location.deletingLastPathComponent().appendingPathComponent(basename)
        let tempDir = fileManager.temporaryDirectory()
        let tbSourceAppDir = (tempDir as NSString).appendingPathComponent(
            kTorBrowserAppBundleBasename)

        // MARK: Write version file
        try fileManager.createDirectory(
            path: kTorBrowserLauncherPath, withIntermediateDirectories: true)
        try fileManager.writeContent(content: basename, toPath: kTorBrowserVersionPath)

        // MARK: Place the DMG
        try fileManager.removeIfExists(url: target)
        try fileManager.moveItem(at: location, to: target)

        // MARK: Attach the DMG
        self.statusHandler(
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "download-status-window-mounting-image", tableName: "Lib", value: "Mounting %@",
                    comment: "Displays when the DMG is being attached (mounted)."), basename))
        try dmgManager.attach(path: target.path, mountPoint: tempDir)

        // MARK: Remove old Tor Browser.app
        self.statusHandler(
            NSLocalizedString(
                "download-status-window-removing-old-version", tableName: "Lib",
                value: "Removing old version.",
                comment: "Displays when the old version of \"Tor Browser.app\" is being deleted."))
        try fileManager.removeIfExists(url: kTorBrowserAppURI)

        // MARK: Copy the bundle
        self.statusHandler(
            NSLocalizedString(
                "download-status-window-copying-app-bundle", tableName: "Lib",
                value: "Copying app bundle.",
                comment: "Displays when the \"Tor Browser.app\" is being copied."))
        try fileManager.copyItem(atPath: tbSourceAppDir, toPath: kTorBrowserAppPath)

        // MARK: Remove quarantine attributes
        self.statusHandler(
            NSLocalizedString(
                "download-status-window-removing-quarantine-attributes", tableName: "Lib",
                value: "Removing quarantine attributes.",
                comment: """
                    Displays when the com.apple.quarantine extended file attribute is being \
                    removed.
                    """))
        try fileManager.removeQuarantineExtendedAttribute(path: kTorBrowserAppPath)

        // MARK: Unmount and remove the DMG.
        try dmgManager.detach()
        try? fileManager.removeIfExists(url: target)
    }

    /// Check if Tor Browser is installed.
    /// - Returns: true if Tor Browser is installed, false otherwise.
    public class func isInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: kTorBrowserVersionPath)
            && FileManager.default.fileExists(atPath: kTorBrowserAppPath)
    }

    /// Launch Tor Browser with the given URLs, if any.
    /// - Parameters:
    ///   - urls: The URLs to open in Tor Browser, if any.
    ///   - opener: A function that opens the application at the given URL with the given
    ///     configuration.
    ///   - launchCompletionHandler: A callback to quit the application.
    /// - Throws: An error if Tor Browser cannot be launched.
    public class func launchAndQuit(
        _ urls: [String]?,
        opener: @escaping (_: URL, _: NSWorkspace.OpenConfiguration) throws -> Void,
        _ launchCompletionHandler: @escaping () -> Void
    ) throws {
        Task {
            let config = NSWorkspace.OpenConfiguration()
            config.arguments = urls ?? []
            config.addsToRecentItems = false
            try opener(kTorBrowserAppURI, config)
            launchCompletionHandler()
        }
    }
}

/// Installer class. Do not use _BaseInstaller directly except in tests.
public typealias BaseInstaller = _BaseInstaller & BaseInstallerProtocol
