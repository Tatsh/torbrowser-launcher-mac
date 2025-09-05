import Foundation

public class DMGManager {
    private var currentMountedDMGPath: String? = nil
    private var mountedFile: String? = nil

    public init() {}

    deinit {
        try? self.detach()
        if mountedFile != nil { try? removeIfExists(url: URL(fileURLWithPath: mountedFile!)) }
    }

    public func attach(path: String, mountPoint: String) throws {
        if currentMountedDMGPath == nil {
            if !FileManager.default.fileExists(atPath: path) {
                throw NSError(domain: "DMGManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "File does not exist."])
            }
            mountedFile = path
            currentMountedDMGPath = mountPoint
            try Self.hdiAttach(path: path, mountPoint: mountPoint)
        } else {
            throw NSError(
                domain: "DMGManager", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "A DMG is already mounted."])
        }
    }

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
