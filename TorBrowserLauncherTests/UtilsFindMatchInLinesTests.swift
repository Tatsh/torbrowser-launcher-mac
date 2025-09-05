import XCTest

@testable import tbl

final class UtilsFindMatchInLinesTests: XCTestCase {
    func testFindMatchInLinesReturnsFirstMatchGroup() {
        let lines = """
            foo bar baz
            version: 12.34.56
            another line
            """
        let regex = try! NSRegularExpression(pattern: #"version: (\d+\.\d+\.\d+)"#)
        let result = findMatchInLines(lines: lines, regex: regex)
        XCTAssertEqual(result, "12.34.56")
    }

    func testFindMatchInLinesReturnsNilIfNoMatch() {
        let lines = """
            foo bar baz
            another line
            """
        let regex = try! NSRegularExpression(pattern: #"version: (\d+\.\d+\.\d+)"#)
        let result = findMatchInLines(lines: lines, regex: regex)
        XCTAssertNil(result)
    }

    func testFindMatchInLinesReturnsFirstMatchIfMultiple() {
        let lines = """
            version: 1.2.3
            version: 4.5.6
            """
        let regex = try! NSRegularExpression(pattern: #"version: (\d+\.\d+\.\d+)"#)
        let result = findMatchInLines(lines: lines, regex: regex)
        XCTAssertEqual(result, "1.2.3")
    }

    func testFindMatchInLinesHandlesEmptyInput() {
        let lines = ""
        let regex = try! NSRegularExpression(pattern: #"version: (\d+\.\d+\.\d+)"#)
        let result = findMatchInLines(lines: lines, regex: regex)
        XCTAssertNil(result)
    }

    func testFindMatchInLinesHandlesNoCaptureGroup() {
        let lines = "version: 1.2.3"
        let regex = try! NSRegularExpression(pattern: #"version: \d+\.\d+\.\d+"#)
        // This regex has no capture group, so range(at: 1) will crash if matched.
        // Let's check that it doesn't crash and returns nil.
        let result = findMatchInLines(lines: lines, regex: regex)
        XCTAssertNil(result)
    }
}
