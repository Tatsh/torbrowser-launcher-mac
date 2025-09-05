import Cocoa

/// Quit the application after a delay.
/// - Parameter offset: The delay in seconds.
public func delayedQuit(_ offset: Double) {
    DispatchQueue.main.asyncAfter(deadline: .now() + offset) { NSApp.terminate(nil) }
}

/// Remove file at URI if it exists.
/// - Parameter url: The file URL to remove.
/// - Throws: An error if the file cannot be removed.
func removeIfExists(url: URL) throws {
    if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
    }
}
