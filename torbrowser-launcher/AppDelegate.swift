import Cocoa

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate,
    NSComboBoxDataSource {
    // MARK: - Outlets

    @IBOutlet var downloadOverSystemTorCheckbox: NSButton!
    @IBOutlet var mirrorPicker: NSComboBox!
    @IBOutlet var settingsWindow: NSWindow!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var torServerTextField: NSTextField!

    // MARK: - Ivars

    private var mirrors = Bundle.main
        .infoDictionary?["TBLMirrors"] as! [String]
    private var selectedMirrorIndex = UserDefaults.standard
        .integer(forKey: "TBLMirrorSelectedIndex")
    private var shouldSave = false
    private var useProxy = false
    private var proxyAddress = "127.0.0.1:9010"

    // MARK: - Application delegate

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_: Notification) {
        let def = UserDefaults.standard
        useProxy = def.bool(forKey: "TBLDownloadOverSystemTor")
        proxyAddress = def
            .string(forKey: "TBLTorSOCKSAddress") ?? "127.0.0.1:9010"
        downloadOverSystemTorCheckbox?.state = useProxy ? .on : .off
        torServerTextField?.stringValue = proxyAddress

        if FileManager.default.fileExists(atPath: kTorBrowserVersionPath),
            FileManager.default.fileExists(atPath: kTorBrowserAppPath) {
            statusLabel.cell?
                .title = NSLocalizedString(
                    "settings-status-label-installed",
                    value: "installed",
                    comment: "Shows \"installed\" if Tor Browser.app is on the system from a previous run."
                )
        }

        if !CommandLine.arguments.contains("--settings") {
            startDownloader(proxy: useProxy ? proxyAddress : nil)
        } else {
            settingsWindow.setIsVisible(true)
        }
    }

    func applicationWillBecomeActive(_: Notification) {
        mirrorPicker.selectItem(at: selectedMirrorIndex)
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

    // MARK: - Combo box data source

    func numberOfItems(in _: NSComboBox) -> Int {
        return mirrors.count
    }

    func comboBox(_: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return mirrors[index]
    }

    // MARK: - Actions

    @IBAction func cancel(_: Any) {
        settingsWindow.close()
    }

    @IBAction func didPressReinstall(sender _: Any) {
        for app in NSWorkspace.shared.runningApplications {
            if let execURL = app.executableURL,
                execURL.lastPathComponent == "firefox",
                execURL.absoluteString.contains("/Tor%20Browser%20Launcher/") {
                app.forceTerminate()
            }
        }
        for path in [kTorBrowserAppPath, kTorBrowserVersionPath] {
            if FileManager.default.fileExists(atPath: path) {
                try! FileManager.default.removeItem(atPath: path)
            }
        }
        startDownloader(proxy: useProxy ? proxyAddress : nil)
        settingsWindow.close()
    }

    @IBAction func saveAndExit(_: Any) {
        shouldSave = true
        settingsWindow.close()
    }

    // MARK: - Private

    private func startDownloader(proxy: String?) {
        let vc = LauncherWindowController()
        Bundle.main.loadNibNamed(
            "LauncherWindow",
            owner: vc,
            topLevelObjects: nil
        )
        // Filter removes Xcode debug arguments
        vc.urls = Array(CommandLine.arguments[1...])
            .filter {
                !$0.starts(with: "-") && $0.lowercased() != "yes" && $0.lowercased() != "no" && !$0
                    .hasPrefix("(")
            }
        vc.downloadTor(proxy: proxy, mirror: mirrors[selectedMirrorIndex])
    }
}
