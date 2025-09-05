import ObjectiveC.runtime
import XCTest

@testable import tbl

var fileExistsCalled = false
var removeItemCalled = false
var shouldFileExist = false
var shouldThrowOnRemove = false

final class MockFileManager: FileManager {
    @objc func mock_fileExists(atPath path: String) -> Bool {
        fileExistsCalled = true
        return shouldFileExist
    }

    @objc func mock_removeItem(at url: URL) throws {
        removeItemCalled = true
        if shouldThrowOnRemove { throw NSError(domain: "MockError", code: 1, userInfo: nil) }
    }
}

final class UtilsRemoveItemIfExistsTests: XCTestCase {
    var mockFileManager: MockFileManager!

    override func setUpWithError() throws {
        mockFileManager = MockFileManager()
        swizzleFileManagerMethods()
    }

    override func tearDownWithError() throws {
        unswizzleFileManagerMethods()
        mockFileManager = nil
    }

    func swizzleFileManagerMethods() {
        let originalFileExists = class_getInstanceMethod(
            FileManager.self, #selector(FileManager.fileExists(atPath:)))
        let mockFileExists = class_getInstanceMethod(
            MockFileManager.self, #selector(MockFileManager.mock_fileExists(atPath:)))
        if let originalFileExists = originalFileExists, let mockFileExists = mockFileExists {
            method_exchangeImplementations(originalFileExists, mockFileExists)
        }

        let originalRemoveItem = class_getInstanceMethod(
            FileManager.self, #selector(FileManager.removeItem(at:)))
        let mockRemoveItem = class_getInstanceMethod(
            MockFileManager.self, #selector(MockFileManager.mock_removeItem(at:)))
        if let originalRemoveItem = originalRemoveItem, let mockRemoveItem = mockRemoveItem {
            method_exchangeImplementations(originalRemoveItem, mockRemoveItem)
        }
    }

    func unswizzleFileManagerMethods() {
        // Swizzling again restores the original implementations
        swizzleFileManagerMethods()
    }

    func testRemoveIfExists_FileExists_RemovesItem() {
        shouldFileExist = true

        removeIfExists(path: "/tmp/testfile")

        XCTAssertTrue(fileExistsCalled)
        XCTAssertTrue(removeItemCalled)
    }

    func testRemoveIfExists_FileDoesNotExist_DoesNotRemoveItem() {
        shouldFileExist = false

        removeIfExists(path: "/tmp/testfile")

        XCTAssertTrue(fileExistsCalled)
        XCTAssertFalse(removeItemCalled)
    }

    func testRemoveIfExists_RemoveThrows_PrintsError() {
        shouldFileExist = true
        shouldThrowOnRemove = true

        removeIfExists(path: "/tmp/testfile")

        XCTAssertTrue(fileExistsCalled)
        XCTAssertTrue(removeItemCalled)
    }
}
