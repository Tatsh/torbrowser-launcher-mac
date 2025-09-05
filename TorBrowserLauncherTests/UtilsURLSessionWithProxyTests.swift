import XCTest

@testable import tbl

final class UtilsURLSessionWithProxyTests: XCTestCase {
    func testURLSessionWithProxySetsProxyConfiguration() {
        let proxy = "192.168.1.100:8888"
        let session = urlSessionWithProxy(proxy)
        let config = session.configuration

        if let proxyDict = config.connectionProxyDictionary {
            XCTAssertEqual(proxyDict[kCFNetworkProxiesHTTPEnable as AnyHashable] as? Bool, true)
            XCTAssertEqual(
                proxyDict[kCFNetworkProxiesHTTPProxy as AnyHashable] as? String, "192.168.1.100")
            XCTAssertEqual(proxyDict[kCFNetworkProxiesHTTPPort as AnyHashable] as? Int, 8888)
        } else {
            XCTFail("Proxy dictionary is nil or of unexpected type")
        }
    }
}
