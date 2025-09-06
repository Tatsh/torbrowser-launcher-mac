import Foundation

/// File does not exist.
public let DMGManagerFileDoesNotExistError = 2
/// Already mounted.
public let DMGManagerAlreadyMountedError = 1

/// DMG manager class.
public class DMGManager {
    private var currentMountedDMGPath: String? = nil
    private var mountedFile: String? = nil

    /// Initialiser.
    public init() {}

    /// Attach the managed DMG.
    /// - Parameters:
    ///   - path: The path to the DMG file.
    ///   - mountPoint: The mount point to use.
    public func attach(path: String, mountPoint: String) throws {
        if currentMountedDMGPath == nil {
            if !FileManager.default.fileExists(atPath: path) {
                throw NSError(
                    domain: "TBLDMGManager", code: DMGManagerFileDoesNotExistError,
                    userInfo: [NSLocalizedDescriptionKey: "File does not exist."])
            }
            mountedFile = path
            currentMountedDMGPath = mountPoint
            try Self.hdiAttach(path: path, mountPoint: mountPoint)
        } else {
            throw NSError(
                domain: "TBLDMGManager", code: DMGManagerAlreadyMountedError,
                userInfo: [NSLocalizedDescriptionKey: "A DMG is already mounted."])
        }
    }

    /// Detach the managed DMG.
    /// - Throws: An error if the DMG cannot be detached.
    public func detach() throws {
        if currentMountedDMGPath != nil { try Self.hdiDetach(path: currentMountedDMGPath!) }
        currentMountedDMGPath = nil
        mountedFile = nil
    }

    private static func hdiAttach(path: String, mountPoint: String) throws {
        try Process.run(
            kHDIUtilURI,
            arguments: [
                "attach", path, "-mountpoint", mountPoint, "-private", "-nobrowse", "-noautoopen",
                "-noautofsck", "-noverify", "-readonly",
            ]
        ).waitUntilExit()
    }

    private static func hdiDetach(path: String) throws {
        try Process.run(kHDIUtilURI, arguments: ["detach", path]).waitUntilExit()
    }
}
