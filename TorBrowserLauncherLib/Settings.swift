import Foundation

/// Settings management.
public class Settings {
    /// Mirror index in the drop down.
    public var mirrorIndex: Int
    /// Proxy address.
    public var proxyAddress: String
    /// Whether to use a proxy.
    public var useProxy: Bool

    /// Initialiser.
    /// - Parameters:
    ///   - mirrorIndex: The mirror index.
    ///   - proxyAddress: The proxy address.
    ///   - useProxy: Whether to use a proxy.
    init(mirrorIndex: Int, proxyAddress: String, useProxy: Bool) {
        self.mirrorIndex = mirrorIndex
        self.proxyAddress = proxyAddress
        self.useProxy = useProxy
    }

    /// Load settings from UserDefaults.
    /// - Returns: The loaded settings.
    public class func load() -> Settings {
        let def = UserDefaults.standard
        return Settings(
            mirrorIndex: def.integer(forKey: "TBLMirrorSelectedIndex"),
            proxyAddress: def.string(forKey: "TBLTorSOCKSAddress") ?? "127.0.0.1:9010",
            useProxy: def.bool(forKey: "TBLDownloadOverSystemTor"))
    }

    /// Persist settings to UserDefaults.
    public func save() {
        let def = UserDefaults.standard
        def.setValue(mirrorIndex, forKey: "TBLMirrorSelectedIndex")
        def.setValue(proxyAddress, forKey: "TBLTorSOCKSAddress")
        def.setValue(useProxy, forKey: "TBLDownloadOverSystemTor")
    }
}
