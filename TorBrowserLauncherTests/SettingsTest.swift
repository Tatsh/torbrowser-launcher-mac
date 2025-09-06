import XCTest

@testable import TorBrowserLauncherLib

final class SettingsTest: XCTestCase {
    override func setUp() {
        super.setUp()
        let def = UserDefaults.standard
        def.removeObject(forKey: "TBLMirrorSelectedIndex")
        def.removeObject(forKey: "TBLTorSOCKSAddress")
        def.removeObject(forKey: "TBLDownloadOverSystemTor")
    }

    func testInitSetsProperties() {
        let settings = Settings(mirrorIndex: 2, proxyAddress: "10.0.0.1:9050", useProxy: true)
        XCTAssertEqual(settings.mirrorIndex, 2)
        XCTAssertEqual(settings.proxyAddress, "10.0.0.1:9050")
        XCTAssertTrue(settings.useProxy)
    }

    func testSaveAndLoad() {
        let settings = Settings(mirrorIndex: 1, proxyAddress: "192.168.1.1:9999", useProxy: false)
        settings.save()

        let loaded = Settings.load()
        XCTAssertEqual(loaded.mirrorIndex, 1)
        XCTAssertEqual(loaded.proxyAddress, "192.168.1.1:9999")
        XCTAssertFalse(loaded.useProxy)
    }

    func testLoadDefaultsWhenNoValuesSet() {
        // UserDefaults is cleared in setUp
        let loaded = Settings.load()
        XCTAssertEqual(loaded.mirrorIndex, 0)
        XCTAssertEqual(loaded.proxyAddress, "127.0.0.1:9010")
        XCTAssertFalse(loaded.useProxy)
    }
}
