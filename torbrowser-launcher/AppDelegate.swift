import Cocoa

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate,
    NSComboBoxDataSource {
    private var mirrors = Bundle.main
        .infoDictionary?["TBLMirrors"] as! [String]
    private var selectedMirrorIndex = UserDefaults.standard
        .integer(forKey: "TBLMirrorSelectedIndex")
    private var shouldSave = false

    @IBOutlet var downloadOverSystemTorCheckbox: NSButton!
    @IBOutlet var mirrorPicker: NSComboBox!
    @IBOutlet var settingsWindow: NSWindow!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var torServerTextField: NSTextField!

    @IBAction func didPressReinstall(sender _: Any) {
        for path in [kTorBrowserAppPath, kTorBrowserVersionPath] {
            if FileManager.default.fileExists(atPath: path) {
                try! FileManager.default.removeItem(atPath: path)
            }
        }
        settingsWindow.setIsVisible(false)
        startDownloader()
    }

    func applicationDidFinishLaunching(_: Notification) {
        let def = UserDefaults.standard
        downloadOverSystemTorCheckbox?.state = def
            .bool(forKey: "TBLDownloadOverSystemTor") ? .on : .off
        torServerTextField?.stringValue = def
            .string(forKey: "TBLTorSOCKSAddress") ?? "127.0.0.1:9010"

        if FileManager.default.fileExists(atPath: kTorBrowserVersionPath),
            FileManager.default.fileExists(atPath: kTorBrowserAppPath) {
            statusLabel.cell?
                .title = NSLocalizedString(
                    "settings-status-label-installed",
                    value: "installed",
                    comment: "Shows \"installed\" if Tor Browser.app is on the system from a previous run"
                )
        }

        if !CommandLine.arguments.contains("--settings") {
            startDownloader()
        } else {
            settingsWindow.setIsVisible(true)
        }
    }

    private func startDownloader() {
        let vc = LauncherWindowController()
        Bundle.main.loadNibNamed(
            "LauncherWindow",
            owner: vc,
            topLevelObjects: nil
        )
        // Filter removes Xcode debug arguments
        vc.urls = Array(CommandLine.arguments[1...])
            .filter { !$0.starts(with: "-") && $0.lowercased() != "yes" }
        vc.downloadTor()
    }

    func applicationWillBecomeActive(_: Notification) {
        mirrorPicker.selectItem(at: selectedMirrorIndex)
    }

    @IBAction func cancel(_: Any) {
        NSApp.terminate(nil)
    }

    @IBAction func saveAndExit(_: Any) {
        shouldSave = true
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_: Notification) {
        if shouldSave {
            let def = UserDefaults.standard
            def
                .setValue(
                    downloadOverSystemTorCheckbox
                        .state == .off ? false : true,
                    forKey: "TBLDownloadOverSystemTor"
                )
            def.setValue(
                torServerTextField.stringValue,
                forKey: "TBLTorSOCKSAddress"
            )
            def.setValue(
                mirrorPicker.indexOfSelectedItem,
                forKey: "TBLMirrorSelectedIndex"
            )
            def.synchronize()
        }
    }

    func numberOfItems(in _: NSComboBox) -> Int {
        return mirrors.count
    }

    func comboBox(_: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return mirrors[index]
    }
}
