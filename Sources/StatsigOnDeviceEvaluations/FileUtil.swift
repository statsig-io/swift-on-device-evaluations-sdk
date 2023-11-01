import Foundation

class FileUtil {
    static let fm = FileManager.default
    static let cacheUrl = fm
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first?
        .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.statsig.OnDeviceEvaluations")
        .appendingPathComponent("StatsigOnDeviceEvaluations")

    static func readFromCache(_ cacheKey: String) -> Data? {
        guard let url = cacheUrl?.appendingPathComponent(cacheKey) else {
            return nil
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }

    static func writeToCache(_ cacheKey: String, _ data: Data) {
        ensureCacheDirectoryExists()

        guard let url = cacheUrl?.appendingPathComponent(cacheKey) else {
            return
        }

        do {
            try data.write(to: url)
        } catch {
            return
        }
    }

    private static func ensureCacheDirectoryExists() {
        guard let url = cacheUrl else {
            return
        }

        if fm.fileExists(atPath: url.path) {
            return
        }

        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return
        }
    }
}
