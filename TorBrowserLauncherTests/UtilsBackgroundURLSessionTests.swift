import XCTest

@testable import tbl

final class UtilsBackgroundURLSessionTests: XCTestCase {
    func testBackgroundURLSessionWithProxySetsProxyConfiguration() {
        let proxy = "127.0.0.1:8080"
        let identifier = "test.session"
        let session = backgroundURLSession(
            withProxy: proxy, identifier: identifier, delegate: nil, delegateQueue: nil)
        let config = session.configuration

        if let proxyDict = config.connectionProxyDictionary {
            XCTAssertEqual(proxyDict[kCFNetworkProxiesHTTPEnable as AnyHashable] as? Bool, true)
            XCTAssertEqual(
                proxyDict[kCFNetworkProxiesHTTPProxy as AnyHashable] as? String, "127.0.0.1")
            XCTAssertEqual(proxyDict[kCFNetworkProxiesHTTPPort as AnyHashable] as? Int, 8080)
        } else {
            XCTFail("Proxy dictionary is nil or of unexpected type")
        }
        XCTAssertEqual(config.identifier, identifier)
    }
}
