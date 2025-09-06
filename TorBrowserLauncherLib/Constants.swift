import Foundation

/// The background activity identifier.
public let kBackgroundIdentifier = "\(Bundle.main.bundleIdentifier!).background"
/// File URI to hdiutil.
let kHDIUtilURI = URL(fileURLWithPath: "/usr/bin/hdiutil")
/// The Tor Browser.app bundle basename.
let kTorBrowserAppBundleBasename = "Tor Browser.app"
private let kAppSupportDirectory = NSSearchPathForDirectoriesInDomains(
    .applicationSupportDirectory, .userDomainMask, true
).first!
/// The full update index URI.
public let kUpdateIndexURI = URL(string: "\(kUpdateURIPrefix)?C=M;O=D")!
/// Regular expression to find update links.
let kUpdateRE: NSRegularExpression = {
    try! NSRegularExpression(pattern: "a href=\"(update_\\d+[^\"]+).*")
}()
/// The full path to the Tor Browser.app.
let kTorBrowserAppPath = (kTorBrowserLauncherPath as NSString).appendingPathComponent(
    kTorBrowserAppBundleBasename)
/// The full URI to the Tor Browser.app.
public let kTorBrowserAppURI = URL(fileURLWithPath: kTorBrowserAppPath, isDirectory: true)
/// The Tor Browser Launcher application support directory.
let kTorBrowserLauncherPath = (kAppSupportDirectory as NSString).appendingPathComponent(
    "Tor Browser Launcher")
/// The full path to the version file.
let kTorBrowserVersionPath = (kTorBrowserLauncherPath as NSString).appendingPathComponent("version")
/// The full path URI to the version file.
public let kTorBrowserVersionURI = URL(fileURLWithPath: kTorBrowserVersionPath)
/// The update URI prefix.
let kUpdateURIPrefix = URL(string: "https://aus1.torproject.org/torbrowser/")!
/// The update URI suffix.
let kUpdateURISuffix = "release/download-macos.json"
