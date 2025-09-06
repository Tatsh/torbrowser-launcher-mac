import Foundation

/// Factory protocol to abstract away creating URLSession instances.
public protocol URLSessionFactory {
    /// Create a URLSession for downloading with optional delegate and proxy settings.
    /// - Parameters:
    ///   - delegate: The delegate for the URLSession.
    ///   - proxy: The proxy settings as a string, if any.
    /// - Returns: A configured URLSession instance.
    func createDownloadSession(delegate: URLSessionDelegate?, proxy: String?) -> URLSession

    /// Create a URLSession configured to use a specified proxy.
    /// - Parameter proxy: The proxy settings as a string.
    /// - Returns: A URLSession instance configured with the given proxy.
    func urlSessionWithProxy(_ proxy: String) -> URLSession
}
