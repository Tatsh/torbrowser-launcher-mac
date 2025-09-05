import Cocoa
import TorBrowserLauncherLib

/// The application delegate.
@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate, NSComboBoxDataSource {
    // MARK: - Outlets

    /// Checkbox to download over system Tor.
    @IBOutlet var downloadOverSystemTorCheckbox: NSButton!
    /// Mirror picker combo box.
    @IBOutlet var mirrorPicker: NSComboBox!
    /// Settings window.
    @IBOutlet var settingsWindow: NSWindow!
    /// Status label.
    @IBOutlet var statusLabel: NSTextField!
    /// Tor server text field.
    @IBOutlet var torServerTextField: NSTextField!

    // MARK: - Ivars
    private lazy var mirrors = Bundle.main.infoDictionary?["TBLMirrors"] as! [String]
    private lazy var settings = Settings.load()
    private var shouldSave = false

    // MARK: - Application delegate

    /// The application should quit when the last window is closed.
    /// - Parameter _: The application.
    /// - Returns: true
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { return true }

    /// On launch, read settings and either show the settings window or start downloading.
    /// - Parameter _: The notification.
    func applicationDidFinishLaunching(_: Notification) {
        downloadOverSystemTorCheckbox?.state = settings.useProxy ? .on : .off
        torServerTextField?.stringValue = settings.proxyAddress
        if Installer.isInstalled() {
            statusLabel.cell?.title = NSLocalizedString(
                "settings-status-label-installed", value: "installed",
                comment:
                    "Shows \"installed\" if Tor Browser.app is on the system from a previous run.")
        }
        if CommandLine.arguments.contains("--settings") {
            settingsWindow.setIsVisible(true)
        } else {
            startDownloader(proxy: settings.useProxy ? settings.proxyAddress : nil)
        }
    }

    /// When the app becomes active, update the mirror picker selection.
    func applicationWillBecomeActive(_: Notification) {
        mirrorPicker.selectItem(at: settings.mirrorIndex)
    }

    /// On terminate, save settings if needed.
    func applicationWillTerminate(_: Notification) {
        if shouldSave {
            settings.useProxy = (downloadOverSystemTorCheckbox.state == .on)
            settings.proxyAddress = torServerTextField.stringValue
            settings.mirrorIndex = mirrorPicker.indexOfSelectedItem
            settings.save()
        }
    }

    // MARK: - Combo box data source

    /// Combo box data source: number of items.
    /// - Returns: The number of items.
    func numberOfItems(in _: NSComboBox) -> Int { return mirrors.count }

    /// Combo box data source: item at index.
    /// - Parameter index: The index.
    /// - Returns: The item at the index.
    func comboBox(_: NSComboBox, objectValueForItemAt index: Int) -> Any? { return mirrors[index] }

    // MARK: - Actions

    /// Action for when the cancel button is pressed.
    /// - Parameter _: The sender (ignored).
    @IBAction func cancel(_: Any) { settingsWindow.close() }

    /// Action for when the reinstall button is pressed.
    @IBAction func didPressReinstall(sender _: Any) {
        do { try Installer.uninstall() } catch {
            statusLabel.cell?.title = String(
                format: NSLocalizedString(
                    "settings-status-label-uninstall-error", value: "Uninstall error: %@",
                    comment: "Shows uninstall error message."), error.localizedDescription)
            return
        }
        startDownloader(proxy: settings.useProxy ? settings.proxyAddress : nil)
        settingsWindow.close()
    }

    /// Action for when the 'Save & Exit' button is pressed.
    @IBAction func saveAndExit(_: Any) {
        shouldSave = true
        settingsWindow.close()
    }

    // MARK: - Private

    private func startDownloader(proxy: String?) {
        LauncherWindowController.setup().start(mirror: mirrors[settings.mirrorIndex], proxy: proxy)
    }
}
