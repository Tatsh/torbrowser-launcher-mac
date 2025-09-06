import Cocoa

/// Quit the application after a delay.
/// - Parameter offset: The delay in seconds.
func delayedQuit(_ offset: Double) {
    DispatchQueue.main.asyncAfter(deadline: .now() + offset) { NSApp.terminate(nil) }
}
