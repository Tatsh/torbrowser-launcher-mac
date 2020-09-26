import Cocoa

func launchTorBrowser(_ urls: [String]?) {
    var config = [NSWorkspace.LaunchConfigurationKey: Any]()
    if urls != nil, !urls!.isEmpty {
        config[NSWorkspace.LaunchConfigurationKey.arguments] = urls
    }
    try! NSWorkspace.shared
        .launchApplication(
            at: URL(fileURLWithPath: kTorBrowserAppPath),
            options: .withoutAddingToRecents,
            configuration: config
        )
}

func hdiAttach(path: String, mountPoint: String) {
    Process.launchedProcess(
        launchPath: "/usr/bin/hdiutil",
        arguments: [
            "attach",
            path,
            "-mountpoint",
            mountPoint,
            "-private",
            "-nobrowse",
            "-noautoopen",
            "-noautofsck",
            "-noverify",
            "-readonly",
        ]
    ).waitUntilExit()
}

func hdiDetach(path: String?) {
    if path != nil {
        hdiDetach(path: path!)
    }
}

func hdiDetach(path: String) {
    Process.launchedProcess(
        launchPath: "/usr/bin/hdiutil",
        arguments: ["detach", path]
    ).waitUntilExit()
}

func quit() {
    DispatchQueue.main.async {
        NSApp.terminate(nil)
    }
}

func delayedQuit(_ offset: Double) {
    DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
        NSApp.terminate(nil)
    }
}

func removeQuarantineExtendedAtributes(path: String) {
    Process.launchedProcess(
        launchPath: "/usr/bin/xattr",
        arguments: [
            "-dr",
            "com.apple.quarantine",
            path,
        ]
    ).waitUntilExit()
}

func urlSessionWithProxy(_ proxy: String) -> URLSession {
    let spl = proxy.split(separator: ":")
    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.connectionProxyDictionary = [
        kCFNetworkProxiesHTTPEnable as AnyHashable: true,
        kCFNetworkProxiesHTTPPort as AnyHashable: Int(spl.last!, radix: 10)!,
        kCFNetworkProxiesHTTPProxy as AnyHashable: spl.first!,
    ]
    return URLSession(configuration: sessionConfiguration)
}

func urlSessionWithProxy(_ proxy: String, delegate: URLSessionDelegate?,
                         delegateQueue: OperationQueue?) -> URLSession {
    let spl = proxy.split(separator: ":")
    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.connectionProxyDictionary = [
        kCFNetworkProxiesHTTPEnable as AnyHashable: true,
        kCFNetworkProxiesHTTPPort as AnyHashable: Int(spl.last!, radix: 10)!,
        kCFNetworkProxiesHTTPProxy as AnyHashable: spl.first!,
    ]
    return URLSession(
        configuration: sessionConfiguration,
        delegate: delegate,
        delegateQueue: delegateQueue
    )
}

func backgroundURLSession(withProxy proxy: String, identifier: String,
                          delegate: URLSessionDelegate?,
                          delegateQueue: OperationQueue?) -> URLSession {
    let spl = proxy.split(separator: ":")
    let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
    sessionConfiguration.connectionProxyDictionary = [
        kCFNetworkProxiesHTTPEnable as AnyHashable: true,
        kCFNetworkProxiesHTTPPort as AnyHashable: Int(spl.last!, radix: 10)!,
        kCFNetworkProxiesHTTPProxy as AnyHashable: spl.first!,
    ]
    return URLSession(
        configuration: sessionConfiguration,
        delegate: delegate,
        delegateQueue: delegateQueue
    )
}

func findMatchInLines(lines: String, regex: NSRegularExpression) -> String? {
    for line in lines.split(separator: "\n") {
        if let m = regex.firstMatch(
            in: String(line),
            options: [],
            range: NSRange(
                location: 0,
                length: line.count
            )
        ) {
            return (String(line) as NSString).substring(with: m.range(at: 1))
        }
    }
    return nil
}

func removeIfExists(path: String) {
    if FileManager.default.fileExists(atPath: path) {
        try! FileManager.default.removeItem(at: URL(fileURLWithPath: path))
    }
}

func locales() -> [String] {
    let locale = NSLocale.preferredLanguages[0]
    var locales =
        [
            locale.replacingOccurrences(of: "-Hans", with: "-CN")
                .replacingOccurrences(of: "-Hant", with: "-TW"),
        ]
    if locale.contains("-") {
        locales
            .append(String(
                locale.split(separator: "-")
                    .first!
            ))
    }
    locales.append("en-US")
    return locales
}
