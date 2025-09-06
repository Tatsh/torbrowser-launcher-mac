import Foundation

/// Simple file manager protocol.
public protocol TBLFileManager {
    /// Copy a file or a directory.
    /// - Parameters:
    ///   - atPath: The source path.
    ///   - toPath: The destination path.
    /// - Throws: An error if the operation fails.
    func copyItem(atPath: String, toPath: String) throws

    /// Create a directory.
    /// - Parameters:
    ///   - path: The path of the directory to create.
    ///   - withIntermediateDirectories: Whether to create intermediate directories if needed.
    /// - Throws: An error if the operation fails.
    func createDirectory(path: String, withIntermediateDirectories: Bool) throws

    /// Create a directory, ignoring any errors.
    /// - Parameters:
    ///   - path: The path of the directory to create.
    ///   - withIntermediateDirectories: Whether to create intermediate directories if needed.
    func createDirectoryIgnoreError(path: String, withIntermediateDirectories: Bool)

    /// Check if a file or directory exists.
    /// - Parameters:
    ///   - atPath: The path to check.
    /// - Returns: True if the file or directory exists, false otherwise.
    func fileExists(atPath: String) -> Bool

    /// Move a file or a directory.
    /// - Parameters:
    ///   - at: The source URL.
    ///   - to: The destination URL.
    /// - Throws: An error if the operation fails.
    func moveItem(at: URL, to: URL) throws

    /// Remove a file or a directory if it exists.
    /// - Parameters:
    ///   - url: The URL of the file or directory to remove.
    /// - Throws: An error if the operation fails.
    func removeIfExists(url: URL) throws

    /// Remove the quarantine extended attribute from a file.
    /// - Parameters:
    ///   - path: The path of the file.
    /// - Throws: An error if the operation fails.
    func removeQuarantineExtendedAttribute(path: String) throws

    /// Get the path to the temporary directory.
    /// - Returns: The path to the temporary directory.
    func temporaryDirectory() -> String

    /// Write a string to a file.
    /// - Parameters:
    ///   - content: The string content to write.
    ///   - toPath: The path of the file to write to.
    /// - Throws: An error if the operation fails.
    func writeContent(content: String, toPath: String) throws
}
