import ObjectiveC
import XCTest

@testable import tbl

final class UtilsRemoveQuarantineExtendedAttributesTests: XCTestCase {
    static var capturedLaunchPath: String?
    static var capturedArguments: [String]?
    static var waitUntilExitCalled = false

    @objc class func swizzled_launchedProcess(launchPath: String, arguments: [String]) -> Process {
        UtilsRemoveQuarantineExtendedAttributesTests.capturedLaunchPath = launchPath
        UtilsRemoveQuarantineExtendedAttributesTests.capturedArguments = arguments
        return SwizzledProcess()
    }

    class SwizzledProcess: Process {
        override func waitUntilExit() {
            UtilsRemoveQuarantineExtendedAttributesTests.waitUntilExitCalled = true
        }
    }

    override func setUp() {
        super.setUp()
        UtilsRemoveQuarantineExtendedAttributesTests.capturedLaunchPath = nil
        UtilsRemoveQuarantineExtendedAttributesTests.capturedArguments = nil
        UtilsRemoveQuarantineExtendedAttributesTests.waitUntilExitCalled = false

        let original = class_getClassMethod(
            Process.self, #selector(Process.launchedProcess(launchPath:arguments:)))
        let swizzled = class_getClassMethod(
            UtilsRemoveQuarantineExtendedAttributesTests.self,
            #selector(
                UtilsRemoveQuarantineExtendedAttributesTests.swizzled_launchedProcess(
                    launchPath:arguments:)))
        method_exchangeImplementations(original!, swizzled!)
    }

    override func tearDown() {
        let original = class_getClassMethod(
            Process.self, #selector(Process.launchedProcess(launchPath:arguments:)))
        let swizzled = class_getClassMethod(
            UtilsRemoveQuarantineExtendedAttributesTests.self,
            #selector(
                UtilsRemoveQuarantineExtendedAttributesTests.swizzled_launchedProcess(
                    launchPath:arguments:)))
        method_exchangeImplementations(swizzled!, original!)
        super.tearDown()
    }

    func testRemoveQuarantineExtendedAttributesCallsProcessWithCorrectArguments() {
        let testPath = "/Applications/Tor Browser.app"
        removeQuarantineExtendedAttributes(path: testPath)

        XCTAssertEqual(
            UtilsRemoveQuarantineExtendedAttributesTests.capturedLaunchPath, "/usr/bin/xattr")
        XCTAssertEqual(
            UtilsRemoveQuarantineExtendedAttributesTests.capturedArguments,
            ["-dr", "com.apple.quarantine", testPath])
        XCTAssertTrue(UtilsRemoveQuarantineExtendedAttributesTests.waitUntilExitCalled)
    }
}
