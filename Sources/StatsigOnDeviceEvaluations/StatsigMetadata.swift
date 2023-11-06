import Foundation

class StatsigMetadata {
    private static var metadata: StatsigMetadata = {
        StatsigMetadata()
    }()
    // SDK Info
    let sdkVersion = "1.0.0"
    let sdkType = "swift-on-device-eval"
    let sessionID: String

    // Device Info
    let appIdentifier: String?
    let appVersion: String?
    let deviceModel: String
    let language: String
    let locale: String
    let systemVersion: String
    let systemName: String
    
    static func get() -> StatsigMetadata {
        return metadata
    }

    private init() {
        let device = DeviceInfo()

        sessionID = UUID().uuidString

        appIdentifier = Bundle.main.bundleIdentifier
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        deviceModel = getDeviceModel(device)
        language = Locale.preferredLanguages[0]
        locale = Locale.current.identifier
        systemName = device.systemName
        systemVersion = device.systemVersion
    }
}

fileprivate func getDeviceModel(_ deviceInfo: DeviceInfo) -> String {
    if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
        return simulatorModelIdentifier
    }

    var sysinfo = utsname()
    uname(&sysinfo)
    if let deviceModel = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii) {
        return deviceModel.trimmingCharacters(in: .controlCharacters)
    }

    return deviceInfo.model
}

extension StatsigMetadata: Loggable {
    func toLoggable() -> [String : Any] {
        var result: [String: String] = [
            "sdkType": sdkType,
            "sdkVersion": sdkVersion,
            "sessionID": sessionID,
//            "stableID": getStableID(overrideStableID),
            "deviceModel": deviceModel,
            "language": language,
            "locale": locale,
            "systemVersion": systemVersion,
            "systemName": systemName
        ]

        if let appIdentifier = appIdentifier {
            result["appIdentifier"] = appIdentifier
        }

        if let appVersion = appVersion {
            result["appVersion"] = appVersion
        }

        return result
    }
}

#if canImport(UIKit)
import UIKit

fileprivate struct DeviceInfo {
    let systemVersion = UIDevice.current.systemVersion
    let systemName = UIDevice.current.systemName
    let model = UIDevice.current.model
}


#elseif canImport(AppKit)
import AppKit

fileprivate struct DeviceInfo {
    let systemVersion: String
    let systemName = "macOS"
    let model: String

    init() {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if let data = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            model = data.text?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"
        } else {
            model = "Unknown"
        }

        IOObjectRelease(service)

        let version = ProcessInfo.processInfo.operatingSystemVersion
        systemVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}

#endif

