import XCTest

@testable import TorBrowserLauncherLib

final class DMGManagerTest: XCTestCase {
    func testAttachNonexistent() {
        let dmgManager = DMGManager()
        XCTAssertThrowsError(
            try dmgManager.attach(path: "/path/to/dmg", mountPoint: "/path/to/mount"))
    }

    func testAttach() {
        let tempDir = FileManager.default.temporaryDirectory
        let dmgURI = tempDir.appendingPathComponent("test.dmg")
        let dmgPath = dmgURI.path
        try? removeIfExists(url: dmgURI)

        // Create a small empty DMG using hdiutil
        do {
            try Process.run(
                kHDIUtilURI,
                arguments: [
                    "create", "-size", "10m", "-fs", "HFS+", "-volname", "TestDMG", dmgPath,
                ]
            ).waitUntilExit()
        } catch { XCTFail("Unexpected error while creating DMG: \(error)") }

        let dmgManager = DMGManager()
        let mountPoint = tempDir.appendingPathComponent("mnt").path
        var thrown = false
        do {
            try FileManager.default.createDirectory(
                atPath: mountPoint, withIntermediateDirectories: true)
            try dmgManager.attach(path: dmgPath, mountPoint: mountPoint)
            do { try dmgManager.attach(path: dmgPath, mountPoint: mountPoint) } catch {
                thrown = true
            }
            try dmgManager.detach()
            XCTAssertTrue(thrown, "Attaching an already mounted DMG should throw an error")
        } catch { XCTFail("Unexpected error: \(error)") }
    }
}
