//
//  LauncherWindow.swift
//  torbrowser-launcher
//
//  Created by Tatsh on 2020-09-19.
//

import Cocoa

let kUpdateURIPrefix = "https://aus1.torproject.org/torbrowser/"
let kUpdateIndexURI = "https://aus1.torproject.org/torbrowser/?C=M;O=D"
let kUpdateRE = "a href=\"(update_[^\"]+).*"

struct Downloads: Codable {
    var downloads: [String: [String: [String: String]]]
    var version: String
}

class LauncherWindowController: NSWindow, NSWindowDelegate, URLSessionDelegate, URLSessionDownloadDelegate {
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!

    var currentMountedDMGPath: String?
    let appSupportDir = (NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Tor Browser Launcher")
    var tbTargetAppDir: String?
    var versionFile: String?
    var lastBasename: String?

    @IBAction func onCancel(_ sender: Any) {
        if currentMountedDMGPath != nil {
            unmount(path: currentMountedDMGPath!)
        }
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }

    func downloadTor() {
        self.progressBar.doubleValue = 0
        self.statusLabel.cell?.title = "Determining update URL"

        self.tbTargetAppDir = (appSupportDir as NSString).appendingPathComponent("Tor Browser.app")
        self.versionFile = (appSupportDir as NSString).appendingPathComponent("version")
        if FileManager.default.fileExists(atPath: versionFile!) {
            self.lastBasename = try? String(contentsOfFile: versionFile!).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let session = URLSession.shared
        let task = session.dataTask(with: URL(string: kUpdateIndexURI)!) { (data, resp, error) in
            if error != nil {
                self.setStatus("Failed to determine update path (error: \(error?.localizedDescription ?? "(none)")). Cannot continue.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    NSApp.terminate(nil)
                }
                return
            }

            let statusCode = (resp as! HTTPURLResponse).statusCode
            if  statusCode < 200 || statusCode > 299 {
                DispatchQueue.main.async {
                    self.statusLabel.cell?.title = "Failed to determine update path (status code \(statusCode). Cannot continue."
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    NSApp.terminate(nil)
                }
                return
            }

            let html = String(data: data!, encoding: .utf8)!.split(separator: "\n")
            let re = try! NSRegularExpression(pattern: kUpdateRE)
            var updatePath: String? = nil
            for line in html {
                let m = re.firstMatch(in: String(line), options: [], range: NSRange(location: 0, length: line.count))
                if m == nil {
                    continue
                }
                updatePath = (String(line) as NSString).substring(with: m!.range(at: 1))
                break
            }

            if updatePath == nil {
                self.setStatus("Failed to determine update path. Cannot continue.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    NSApp.terminate(nil)
                }
                return
            }

            self.setStatus("Creating \(self.appSupportDir)")
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: self.appSupportDir), withIntermediateDirectories: false, attributes: nil)

            self.setStatus("Fetching downloads.json")
            let downloadsJSON = kUpdateURIPrefix.appending(updatePath!).appending("release/downloads.json")
            session.dataTask(with: URL(string: downloadsJSON)!) { (data, resp, error) in
                if error != nil {
                    print(error?.localizedDescription ?? "No description")
                    return
                }
                let decoder = JSONDecoder()
                let downloads = try! decoder.decode(Downloads.self, from: data!)
                let localizedValue = downloads.downloads["osx64"]!["en-US"]
                let binary = localizedValue!["binary"]!
                let basename = (binary as NSString).lastPathComponent

                if  self.lastBasename == basename {
                    self.setStatus("Launching Tor Browser")
                    try! NSWorkspace.shared.launchApplication(at: URL(fileURLWithPath: self.tbTargetAppDir!), options: .withoutAddingToRecents, configuration: [NSWorkspace.LaunchConfigurationKey : Any]())
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NSApp.terminate(nil)
                    }
                } else {
                    // TODO Implement signature checking with GPG
                    // let sig = localizedValue!["sig"]!
                    self.setStatus("Fetching \(basename)")
                    let dmgSession = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background"), delegate: self, delegateQueue: OperationQueue())
                    dmgSession.downloadTask(with: URL(string: binary)!).resume()
                }
            }.resume()
        }
        task.resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let basename = ((downloadTask.currentRequest?.url!.absoluteString)! as NSString).lastPathComponent
        let target = location.deletingLastPathComponent().appendingPathComponent(basename)
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(ProcessInfo().globallyUniqueString)
        let tbSourceAppDir = (tempDir as NSString).appendingPathComponent("Tor Browser.app")
        let tbTargetAppDir = (appSupportDir as NSString).appendingPathComponent("Tor Browser.app")
        try! basename.write(toFile: self.versionFile!, atomically: true, encoding: .ascii)

        try? FileManager.default.removeItem(at: target)
        try! FileManager.default.moveItem(at: location, to: target)

        setStatus("Mounting \(basename)")
        Process.launchedProcess(launchPath: "/usr/bin/hdiutil", arguments: ["attach", target.path, "-mountpoint", tempDir, "-private", "-nobrowse", "-noautoopen", "-noautofsck",  "-noverify", "-readonly"]).waitUntilExit()
        currentMountedDMGPath = tempDir

        setStatus("Removing old version")
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: tbTargetAppDir))

        setStatus("Copying app bundle")
        try! FileManager.default.copyItem(atPath: tbSourceAppDir, toPath: tbTargetAppDir)

        setStatus("Unmounting \(basename)")
        unmount(path: tempDir)
        currentMountedDMGPath = nil

        setStatus("Removing quarantine attributes")
        Process.launchedProcess(launchPath: "/usr/bin/xattr", arguments: ["-dr", "com.apple.quarantine", tbTargetAppDir]).waitUntilExit()

        setStatus("Launching Tor Browser")
        try! NSWorkspace.shared.launchApplication(at: URL(fileURLWithPath: tbTargetAppDir), options: .withoutAddingToRecents, configuration: [NSWorkspace.LaunchConfigurationKey : Any]())

        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }

    func unmount(path: String) {
        Process.launchedProcess(launchPath: "/usr/bin/hdiutil", arguments: ["detach", path]).waitUntilExit()
    }

    func setStatus(_ s: String) {
        DispatchQueue.main.async {
            self.statusLabel.cell?.title = s
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.progressBar.maxValue = Double(totalBytesExpectedToWrite)
            self.progressBar.doubleValue = Double(totalBytesWritten)
        }
    }
}
