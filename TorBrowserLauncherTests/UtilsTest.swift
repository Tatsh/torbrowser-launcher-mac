import XCTest

@testable import TorBrowserLauncherLib

final class UtilsTest: XCTestCase {
    func testRemoveIfExists_removesFileIfExists() throws {
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(
            atPath: tempFile.path, contents: Data("test".utf8), attributes: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile.path))

        // Attempt to remove
        try removeIfExists(url: tempFile)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFile.path))
    }

    func testRemoveIfExists_doesNothingIfFileDoesNotExist() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFile.path))

        // Should not throw
        XCTAssertNoThrow(try removeIfExists(url: tempFile))
    }
}
