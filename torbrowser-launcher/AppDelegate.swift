//
//  AppDelegate.swift
//  torbrowser-launcher
//
//  Created by Tatsh on 2020-09-19.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSComboBoxDataSource {
    private var mirrors = Bundle.main.infoDictionary?["TBLMirrors"] as! [String]
    private var selectedMirrorIndex: Int?
    private var shouldSave = false

    @IBOutlet var settingsWindow: NSWindow!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var downloadOverSystemTorCheckbox: NSButton!
    @IBOutlet weak var torServerTextField: NSTextField!
    @IBOutlet weak var reinstallTorBrowserButton: NSButton!
    @IBOutlet weak var mirrorPicker: NSComboBox!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var saveAndExitButton: NSButton!

    @IBAction func didPressReinstall(sender: Any) {
        let tbPath = getTorBrowserPath()
        let versionPath = (tbPath as NSString).deletingLastPathComponent.appending("/version")
        if FileManager.default.fileExists(atPath: tbPath) {
            try! FileManager.default.removeItem(atPath: tbPath)
        }
        if FileManager.default.fileExists(atPath: versionPath) {
            try! FileManager.default.removeItem(atPath: versionPath)
        }
        self.settingsWindow.setIsVisible(false)
        let vc = LauncherWindowController()
        Bundle.main.loadNibNamed("LauncherWindow", owner: vc, topLevelObjects: nil)
        vc.downloadTor(urls: Array(CommandLine.arguments[1...]))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let def = UserDefaults.standard
        if def.bool(forKey: "TBLDownloadOverSystemTor") {
            downloadOverSystemTorCheckbox?.state = .on
        } else {
            downloadOverSystemTorCheckbox?.state = .off
        }
        torServerTextField?.stringValue = def.string(forKey: "TBLTorSOCKSAddress") ?? "127.0.0.1:9010"
        selectedMirrorIndex = def.integer(forKey: "TBLMirrorSelectedIndex")

        let tbPath = getTorBrowserPath()
        if FileManager.default.fileExists(atPath: tbPath) {
            self.statusLabel.cell?.title = NSLocalizedString("settings-status-label-installed", comment: "Shows \"installed\" if Tor Browser.app is on the system from a previous run")
        }

        if !CommandLine.arguments.contains("--settings") {
            let vc = LauncherWindowController()
            Bundle.main.loadNibNamed("LauncherWindow", owner: vc, topLevelObjects: nil)
            vc.downloadTor(urls: Array(CommandLine.arguments[1...]))
        } else {
            self.settingsWindow.setIsVisible(true)
        }
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        mirrorPicker?.selectItem(at: selectedMirrorIndex ?? 0)
    }

    @IBAction func cancel(_ sender: Any) {
        NSApp.terminate(nil)
    }

    @IBAction func saveAndExit(_ sender: Any) {
        shouldSave = true
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if shouldSave {
            let def = UserDefaults.standard
            def.setValue(downloadOverSystemTorCheckbox?.state == .off ? false : true, forKey: "TBLDownloadOverSystemTor")
            def.setValue(torServerTextField?.stringValue, forKey: "TBLTorSOCKSAddress")
            def.setValue(mirrorPicker?.indexOfSelectedItem, forKey: "TBLMirrorSelectedIndex")
            def.synchronize()
        }
    }

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return mirrors.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return mirrors[index]
    }
}
