import XCTest

@testable import TorBrowserLauncherLib

class MockInstaller: BaseInstaller {
    static var installed = false
    static var launchAndQuitCalled = false
    static var launchAndQuitURLs: [String]? = nil

    static override func isInstalled() -> Bool { installed }
    static func uninstall(fileManager: TBLFileManager, completionHandler: (() -> Void)?) throws {}
    static override func launchAndQuit(
        _ urls: [String]?, opener: @escaping (URL, NSWorkspace.OpenConfiguration) throws -> Void,
        _ launchCompletionHandler: @escaping () -> Void
    ) throws {
        launchAndQuitCalled = true
        launchAndQuitURLs = urls
        launchCompletionHandler()
    }
}

class MockURLSessionFactory: URLSessionFactory {
    func backgroundURLSession(
        withProxy proxy: String, identifier: String, delegate: URLSessionDelegate?,
        delegateQueue: OperationQueue?
    ) -> URLSession {
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: delegateQueue)
    }

    func createDownloadSession(delegate: URLSessionDelegate?, proxy: String?) -> URLSession {
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }

    func urlSessionWithProxy(_ proxy: String) -> URLSession {
        return URLSession(configuration: .default)
    }
}

final class DownloaderTest: XCTestCase {
    var statusMessages: [String] = []
    var launchCompletionHandlerCalled = false

    override func setUp() {
        statusMessages = []
        launchCompletionHandlerCalled = false
        MockInstaller.installed = false
        MockInstaller.launchAndQuitCalled = false
        MockInstaller.launchAndQuitURLs = nil
    }

    func testDownloadsAndDoesNotLaunchIfNotInstalled() throws {
        let expectedBasename = "tor-browser-macos-14.5.6.dmg"

        // Prepare a local downloads.json file
        let tempDir = NSTemporaryDirectory()
        try "Test file".write(
            to: URL(
                fileURLWithPath: (tempDir as NSString).appendingPathComponent(expectedBasename)),
            atomically: true, encoding: .utf8)
        let downloadsJSON = "{\"binary\":\"file://\(tempDir)/\(expectedBasename)\"}"
        let subdir = "update_9z"
        // ${tmp}/update_9/downloads.json
        let update9DirPath = (tempDir as NSString).appendingPathComponent(subdir)
        try FileManager.default.createDirectory(
            atPath: update9DirPath, withIntermediateDirectories: true)
        let downloadsJSONPath = (update9DirPath as NSString).appendingPathComponent(
            "downloads.json")
        try downloadsJSON.data(using: .utf8)?.write(to: URL(fileURLWithPath: downloadsJSONPath))

        // Prepare a fake update index HTML with the update path
        let updateIndexHTML = "<a href=\"\(subdir)\">downloads.json</a>"
        let updateIndexPath = (tempDir as NSString).appendingPathComponent("index.html")
        try updateIndexHTML.data(using: .utf8)?.write(to: URL(fileURLWithPath: updateIndexPath))

        // Use file:// URLs for the test
        let mirror = "file://\(tempDir)"

        try? removeIfExists(url: kTorBrowserVersionURI)
        MockInstaller.installed = false

        let downloader = Downloader(
            delegate: nil, fileManager: MockFileManager(), installerType: MockInstaller.self,
            launchCompletionHandler: { self.launchCompletionHandlerCalled = true }, mirror: mirror,
            opener: { _, _ in }, proxy: nil, statusHandler: { self.statusMessages.append($0) },
            updateIndexURI: URL(fileURLWithPath: updateIndexPath),
            urlSessionFactory: MockURLSessionFactory(), urls: ["https://check.torproject.org/"])
        downloader.updateURIPrefix = URL(string: mirror)!
        downloader.updateURISuffix = "downloads.json"
        try downloader.download()

        XCTAssertFalse(MockInstaller.launchAndQuitCalled)
        XCTAssertFalse(launchCompletionHandlerCalled)
        XCTAssertTrue(statusMessages.contains(where: { $0.contains("Getting update URL.") }))
        XCTAssertFalse(statusMessages.contains(where: { $0.contains("Launching Tor Browser.") }))
    }

    func testLaunchesIfAlreadyInstalled() throws {
        class DummyDelegate: NSObject, URLSessionDelegate {}
        let expectedBasename = "tor-browser-macos-14.5.6.dmg"

        // Prepare a local downloads.json file
        let tempDir = NSTemporaryDirectory()
        try "Test file".write(
            to: URL(
                fileURLWithPath: (tempDir as NSString).appendingPathComponent(expectedBasename)),
            atomically: true, encoding: .utf8)
        let downloadsJSON = "{\"binary\":\"file://\(tempDir)/\(expectedBasename)\"}"
        let subdir = "update_9z"
        // ${tmp}/update_9/downloads.json
        let update9DirPath = (tempDir as NSString).appendingPathComponent(subdir)
        try FileManager.default.createDirectory(
            atPath: update9DirPath, withIntermediateDirectories: true)
        let downloadsJSONPath = (update9DirPath as NSString).appendingPathComponent(
            "downloads.json")
        try downloadsJSON.data(using: .utf8)?.write(to: URL(fileURLWithPath: downloadsJSONPath))

        // Prepare a fake update index HTML with the update path
        let updateIndexHTML = "<a href=\"\(subdir)\">downloads.json</a>"
        let updateIndexPath = (tempDir as NSString).appendingPathComponent("index.html")
        try updateIndexHTML.data(using: .utf8)?.write(to: URL(fileURLWithPath: updateIndexPath))

        // Use file:// URLs for the test
        let mirror = "file://\(tempDir)"

        // Write the expected version file to simulate "already installed"
        try expectedBasename.write(
            toFile: kTorBrowserVersionPath, atomically: true, encoding: .ascii)
        MockInstaller.installed = true

        let exp = expectation(description: "launchCompletionHandler called")
        let downloader = Downloader(
            delegate: DummyDelegate(), fileManager: MockFileManager(),
            installerType: MockInstaller.self,
            launchCompletionHandler: {
                self.launchCompletionHandlerCalled = true
                exp.fulfill()
            }, mirror: mirror, opener: { _, _ in }, proxy: nil,
            statusHandler: { self.statusMessages.append($0) },
            updateIndexURI: URL(fileURLWithPath: updateIndexPath),
            urlSessionFactory: MockURLSessionFactory(), urls: ["https://check.torproject.org/"])
        downloader.updateURIPrefix = URL(string: mirror)!
        downloader.updateURISuffix = "downloads.json"
        try downloader.download()
        wait(for: [exp], timeout: 5)

        XCTAssertTrue(MockInstaller.launchAndQuitCalled)
        XCTAssertEqual(MockInstaller.launchAndQuitURLs, ["https://check.torproject.org/"])
        XCTAssertTrue(launchCompletionHandlerCalled)
        XCTAssertTrue(statusMessages.contains(where: { $0.contains("Getting update URL.") }))
        XCTAssertTrue(statusMessages.contains(where: { $0.contains("Launching Tor Browser.") }))
    }
}
