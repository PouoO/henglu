import Foundation

/// Installs the bundled Alpine rootfs into the app's Documents directory on first launch.
final class RootfsManager {
    static let shared = RootfsManager()

    private init() {}

    var rootfsPath: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("alpine-rootfs")
    }

    var dataPath: URL {
        return rootfsPath.appendingPathComponent("data")
    }

    var isInstalled: Bool {
        return FileManager.default.fileExists(atPath: rootfsPath.path)
    }

    func installIfNeeded() throws {
        guard !isInstalled else { return }
        guard let zipURL = Bundle.main.url(forResource: "alpine-rootfs", withExtension: "zip") else {
            throw ISHError.rootfsZipMissing
        }
        let fm = FileManager.default
        if fm.fileExists(atPath: rootfsPath.path) {
            try fm.removeItem(at: rootfsPath)
        }
        try fm.createDirectory(at: rootfsPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        let ok = ISHZipUtil.extractZip(at: zipURL, toDirectory: rootfsPath)
        if !ok {
            throw ISHError.rootfsExtractionFailed
        }
    }
}

enum ISHError: Error {
    case rootfsZipMissing
    case rootfsExtractionFailed
    case kernelBootFailed
    case shellStartFailed
}
