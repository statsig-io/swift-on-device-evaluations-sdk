import Foundation

@objc public class GetDynamicConfigOptions: NSObject {
    @objc public var disableExposureLogging: Bool = false
    
    static func disabledExposures() -> GetDynamicConfigOptions {
        let opts = GetDynamicConfigOptions()
        opts.disableExposureLogging = true
        return opts
    }
}
