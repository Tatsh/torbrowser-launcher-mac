import ObjectiveC
import XCTest

@testable import tbl

final class UtilsHDIDetachTests: XCTestCase {
    static var capturedLaunchPath: String?
    static var capturedArguments: [String]?
    static var waitUntilExitCalled = false

    @objc class func swizzled_launchedProcess(launchPath: String, arguments: [String]) -> Process {
        UtilsHDIDetachTests.capturedLaunchPath = launchPath
        UtilsHDIDetachTests.capturedArguments = arguments
        return SwizzledProcess()
    }

    class SwizzledProcess: Process {
        override func waitUntilExit() { UtilsHDIDetachTests.waitUntilExitCalled = true }
    }

    override func setUp() {
        super.setUp()
        UtilsHDIDetachTests.capturedLaunchPath = nil
        UtilsHDIDetachTests.capturedArguments = nil
        UtilsHDIDetachTests.waitUntilExitCalled = false

        let original = class_getClassMethod(
            Process.self, #selector(Process.launchedProcess(launchPath:arguments:)))
        let swizzled = class_getClassMethod(
            UtilsHDIDetachTests.self,
            #selector(UtilsHDIDetachTests.swizzled_launchedProcess(launchPath:arguments:)))
        method_exchangeImplementations(original!, swizzled!)
    }

    override func tearDown() {
        let original = class_getClassMethod(
            Process.self, #selector(Process.launchedProcess(launchPath:arguments:)))
        let swizzled = class_getClassMethod(
            UtilsHDIDetachTests.self,
            #selector(UtilsHDIDetachTests.swizzled_launchedProcess(launchPath:arguments:)))
        method_exchangeImplementations(swizzled!, original!)
        super.tearDown()
    }

    func testHdiDetachWithStringCallsProcessWithCorrectArguments() {
        let testPath = "/Volumes/Test"
        hdiDetach(path: testPath)

        XCTAssertEqual(UtilsHDIDetachTests.capturedLaunchPath, "/usr/bin/hdiutil")
        XCTAssertEqual(UtilsHDIDetachTests.capturedArguments, ["detach", testPath])
        XCTAssertTrue(UtilsHDIDetachTests.waitUntilExitCalled)
    }

    func testHdiDetachWithOptionalStringCallsProcess() {
        let testPath: String? = "/Volumes/Optional"
        hdiDetach(path: testPath)

        XCTAssertEqual(UtilsHDIDetachTests.capturedLaunchPath, "/usr/bin/hdiutil")
        XCTAssertEqual(UtilsHDIDetachTests.capturedArguments, ["detach", "/Volumes/Optional"])
        XCTAssertTrue(UtilsHDIDetachTests.waitUntilExitCalled)
    }

    func testHdiDetachWithNilDoesNothing() {
        let testPath: String? = nil
        hdiDetach(path: testPath)

        XCTAssertNil(UtilsHDIDetachTests.capturedLaunchPath)
        XCTAssertNil(UtilsHDIDetachTests.capturedArguments)
        XCTAssertFalse(UtilsHDIDetachTests.waitUntilExitCalled)
    }
}
