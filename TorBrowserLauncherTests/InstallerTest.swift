import XCTest

@testable import TorBrowserLauncherLib

class MockDMGManager: DMGManager {
    var attachCalled = false
    var attachPath: String?
    var attachMountPoint: String?
    override func attach(path: String, mountPoint: String) throws {
        attachCalled = true
        attachPath = path
        attachMountPoint = mountPoint
    }
}

class MockFileManager: TBLFileManager {
    var createdDirs: [String] = []
    var copiedItems: [(atPath: String, toPath: String)] = []
    var movedItems: [(at: URL, to: URL)] = []
    var removedItems: [URL] = []
    var quarantineRemovedPaths: [String] = []
    var tempDirectoriesCreated: [String] = []

    func copyItem(atPath: String, toPath: String) throws { copiedItems.append((atPath, toPath)) }

    func createDirectory(path: String, withIntermediateDirectories intermediate: Bool) {
        createdDirs.append(path)
    }

    func createDirectoryIgnoreError(
        path: String, withIntermediateDirectories intermediate: Bool = true
    ) { createdDirs.append(path) }

    func fileExists(atPath path: String) -> Bool { return false }

    func moveItem(at: URL, to: URL) throws { movedItems.append((at, to)) }

    func removeIfExists(url: URL) throws { removedItems.append(url) }

    func removeQuarantineExtendedAttribute(path: String) throws {
        quarantineRemovedPaths.append(path)
    }

    func temporaryDirectory() -> String {
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            ProcessInfo().globallyUniqueString)
        tempDirectoriesCreated.append(tempDir)
        return tempDir
    }

    func writeContent(content: String, toPath path: String) throws {}
}

class BaseInstallerTests: XCTestCase {
    var mockDMGManager: MockDMGManager!
    var statusMessages: [String]!

    override func setUp() {
        super.setUp()
        mockDMGManager = MockDMGManager()
        statusMessages = []
    }

    override func tearDown() {
        try? removeIfExists(url: kTorBrowserAppURI)
        try? removeIfExists(url: kTorBrowserVersionURI)
        super.tearDown()
    }

    func testInstall() {
        let mockFileManager = MockFileManager()
        let installer = _BaseInstaller(
            absoluteURI: "https://example.com/TorBrowser.dmg", dmgManager: mockDMGManager,
            fileManager: mockFileManager
        ) { status in self.statusMessages.append(status) }

        // Create a dummy DMG file
        let tempDMGPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(
            "TorBrowser.dmg")
        FileManager.default.createFile(atPath: tempDMGPath, contents: Data(), attributes: nil)

        do { try installer.install(location: URL(fileURLWithPath: tempDMGPath)) } catch {
            XCTFail("Installation failed with error: \(error)")
        }

        // Verify DMG was attached
        XCTAssertTrue(mockDMGManager.attachCalled)
        XCTAssertEqual(mockDMGManager.attachPath, tempDMGPath)
        XCTAssertNotNil(mockDMGManager.attachMountPoint)

        // Verify status messages
        XCTAssertTrue(statusMessages.contains(where: { $0.contains("Mounting") }))
        XCTAssertTrue(statusMessages.contains(where: { $0.contains("Removing old version") }))
        XCTAssertTrue(statusMessages.contains(where: { $0.contains("Copying app bundle") }))
        XCTAssertTrue(
            statusMessages.contains(where: { $0.contains("Removing quarantine attributes") }))

        // Verify file operations
        XCTAssertEqual(mockFileManager.removedItems.count, 3)
        XCTAssertEqual(mockFileManager.copiedItems.count, 1)
        XCTAssertEqual(mockFileManager.quarantineRemovedPaths.count, 1)
        XCTAssertEqual(mockFileManager.quarantineRemovedPaths.first, kTorBrowserAppPath)

        // Clean up
        try? removeIfExists(url: URL(fileURLWithPath: tempDMGPath))
    }

    func testIsInstalledTrueAndFalse() throws {
        let fm = FileManager.default

        try? removeIfExists(url: kTorBrowserAppURI)
        try? removeIfExists(url: kTorBrowserVersionURI)

        // Setup: create dummy files
        try fm.createDirectory(atPath: kTorBrowserAppPath, withIntermediateDirectories: true)
        XCTAssertTrue(
            fm.createFile(atPath: kTorBrowserVersionPath, contents: Data(), attributes: nil))
        XCTAssertTrue(_BaseInstaller.isInstalled())

        // Remove files
        try? removeIfExists(url: kTorBrowserAppURI)
        try? removeIfExists(url: kTorBrowserVersionURI)
        XCTAssertFalse(_BaseInstaller.isInstalled())
    }

    func testLaunchAndQuitCallsCompletionHandler() async throws {
        let exp = expectation(description: "launchCompletionHandler called")
        try _BaseInstaller.launchAndQuit(
            ["https://example.com"],
            opener: { appURI, config in
                XCTAssertEqual(appURI, kTorBrowserAppURI)
                XCTAssertEqual(config.arguments, ["https://example.com"])
                XCTAssertEqual(config.addsToRecentItems, false)
            }
        ) { exp.fulfill() }
        await fulfillment(of: [exp], timeout: 2)
    }
}
