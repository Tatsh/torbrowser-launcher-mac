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

    func testInvalidBinaryURI() throws {
        let expectedBasename = "tor-browser-macos-14.5.6.dmg"

        // Prepare a local downloads.json file
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

        try "Test file".write(
            to: URL(
                fileURLWithPath: (tempDir as NSString).appendingPathComponent(expectedBasename)),
            atomically: true, encoding: .utf8)
        let downloadsJSON = "{\"binary\":\"\"}"
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
            opener: { _, _ in }, proxy: nil,
            statusHandler: {
                print("testNoBinaryURI: \($0)")
                self.statusMessages.append($0)
            }, updateIndexURI: URL(fileURLWithPath: updateIndexPath),
            urlSessionFactory: MockURLSessionFactory(), urls: ["https://check.torproject.org/"])
        downloader.updateURIPrefix = URL(string: mirror)!
        downloader.updateURISuffix = "downloads.json"

        let exp = expectation(description: "taskErrorHandler called")
        try downloader.download(taskCompletionHandler: nil) { error in
            XCTAssertTrue(error.localizedDescription.contains("Invalid binary URL."))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        XCTAssertFalse(MockInstaller.launchAndQuitCalled)
        XCTAssertFalse(self.launchCompletionHandlerCalled)
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Getting update URL.") }))
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Finding update path.") }))
        XCTAssertFalse(
            self.statusMessages.contains(where: { $0.contains("Launching Tor Browser.") }))
    }

    func testNoBinaryURI() throws {
        let expectedBasename = "tor-browser-macos-14.5.6.dmg"

        // Prepare a local downloads.json file
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

        try "Test file".write(
            to: URL(
                fileURLWithPath: (tempDir as NSString).appendingPathComponent(expectedBasename)),
            atomically: true, encoding: .utf8)
        let downloadsJSON = "{\"binary\":null}"
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

        let exp = expectation(description: "taskErrorHandler called")
        try downloader.download(taskCompletionHandler: { print("Task completion handler called.") })
        { error in
            XCTAssertTrue(
                error.localizedDescription.contains("No binary URL found in downloads.json"))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        XCTAssertFalse(MockInstaller.launchAndQuitCalled)
        XCTAssertFalse(self.launchCompletionHandlerCalled)
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Getting update URL.") }))
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Finding update path.") }))
        XCTAssertFalse(
            self.statusMessages.contains(where: { $0.contains("Launching Tor Browser.") }))
    }

    func testInvalidIndexFile() throws {
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

        // Prepare a fake update index HTML with the update path
        let updateIndexPath = (tempDir as NSString).appendingPathComponent("index.html")
        try Data([0x80]).write(to: URL(fileURLWithPath: updateIndexPath))

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

        let exp = expectation(description: "taskErrorHandler called")
        try downloader.download(taskCompletionHandler: nil) { error in
            XCTAssertTrue(
                error.localizedDescription.contains("Failed to read HTML content as UTF-8"))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        XCTAssertFalse(MockInstaller.launchAndQuitCalled)
        XCTAssertFalse(self.launchCompletionHandlerCalled)
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Getting update URL.") }))
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Finding update path.") }))
        XCTAssertFalse(self.statusMessages.contains(where: { $0.contains("Creating '") }))
    }

    func testNoMatchInIndexHTML() throws {
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

        // Prepare a fake update index HTML with the update path
        let updateIndexHTML = "Not matching."
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

        let exp = expectation(description: "taskErrorHandler called")
        try downloader.download(taskCompletionHandler: nil) { error in
            XCTAssertTrue(error.localizedDescription.contains("Failed to find update path in HTML"))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        XCTAssertFalse(MockInstaller.launchAndQuitCalled)
        XCTAssertFalse(self.launchCompletionHandlerCalled)
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Getting update URL.") }))
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Finding update path.") }))
        XCTAssertFalse(self.statusMessages.contains(where: { $0.contains("Creating '") }))
    }

    func testDownloadsAndDoesNotLaunchIfNotInstalled() throws {
        let expectedBasename = "tor-browser-macos-14.5.6.dmg"

        // Prepare a local downloads.json file
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

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

        let exp = expectation(description: "taskCompletionHandler called")
        try downloader.download(taskCompletionHandler: { exp.fulfill() })
        wait(for: [exp], timeout: 5)

        XCTAssertFalse(MockInstaller.launchAndQuitCalled)
        XCTAssertFalse(self.launchCompletionHandlerCalled)
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Getting update URL.") }))
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Finding update path.") }))
        XCTAssertTrue(self.statusMessages.contains(where: { $0.contains("Creating '") }))
        XCTAssertTrue(
            self.statusMessages.contains(where: {
                $0.contains("Fetching tor-browser-macos-14.5.6.dmg")
            }))
        XCTAssertFalse(
            self.statusMessages.contains(where: { $0.contains("Launching Tor Browser.") }))
    }

    func testLaunchesIfAlreadyInstalled() throws {
        class DummyDelegate: NSObject, URLSessionDelegate {}
        let expectedBasename = "tor-browser-macos-14.5.6.dmg"

        // Prepare a local downloads.json file
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

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
