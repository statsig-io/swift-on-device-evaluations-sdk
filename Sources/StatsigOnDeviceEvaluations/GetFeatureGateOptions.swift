import Foundation

@objc public class GetFeatureGateOptions: NSObject {
    @objc public var disableExposureLogging: Bool = false
    
    static func disabledExposures() -> GetFeatureGateOptions {
        let opts = GetFeatureGateOptions()
        opts.disableExposureLogging = true
        return opts
    }
}
