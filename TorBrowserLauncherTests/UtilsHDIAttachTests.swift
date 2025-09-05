import ObjectiveC
import XCTest

@testable import tbl

final class UtilsHDIAttachTests: XCTestCase {
    // Storage for captured arguments
    static var capturedLaunchPath: String?
    static var capturedArguments: [String]?
    static var waitUntilExitCalled = false

    // Swizzled implementation for launchedProcess
    @objc class func swizzled_launchedProcess(launchPath: String, arguments: [String]) -> Process {
        UtilsHDIAttachTests.capturedLaunchPath = launchPath
        UtilsHDIAttachTests.capturedArguments = arguments
        return SwizzledProcess()
    }

    // Dummy Process subclass to swizzle waitUntilExit
    class SwizzledProcess: Process {
        override func waitUntilExit() { UtilsHDIAttachTests.waitUntilExitCalled = true }
    }

    override func setUp() {
        super.setUp()
        UtilsHDIAttachTests.capturedLaunchPath = nil
        UtilsHDIAttachTests.capturedArguments = nil
        UtilsHDIAttachTests.waitUntilExitCalled = false

        // Swizzle Process.launchedProcess
        let original = class_getClassMethod(
            Process.self, #selector(Process.launchedProcess(launchPath:arguments:)))
        let swizzled = class_getClassMethod(
            UtilsHDIAttachTests.self,
            #selector(UtilsHDIAttachTests.swizzled_launchedProcess(launchPath:arguments:)))
        method_exchangeImplementations(original!, swizzled!)
    }

    override func tearDown() {
        // Undo swizzle
        let original = class_getClassMethod(
            Process.self, #selector(Process.launchedProcess(launchPath:arguments:)))
        let swizzled = class_getClassMethod(
            UtilsHDIAttachTests.self,
            #selector(UtilsHDIAttachTests.swizzled_launchedProcess(launchPath:arguments:)))
        method_exchangeImplementations(swizzled!, original!)
        super.tearDown()
    }

    func testHdiAttachCallsProcessWithCorrectArguments() {
        let testPath = "/tmp/test.dmg"
        let testMount = "/Volumes/Test"
        hdiAttach(path: testPath, mountPoint: testMount)

        XCTAssertEqual(UtilsHDIAttachTests.capturedLaunchPath, "/usr/bin/hdiutil")
        XCTAssertEqual(
            UtilsHDIAttachTests.capturedArguments,
            [
                "attach", testPath, "-mountpoint", testMount, "-private", "-nobrowse",
                "-noautoopen", "-noautofsck", "-noverify", "-readonly",
            ])
        XCTAssertTrue(UtilsHDIAttachTests.waitUntilExitCalled)

    }
}
