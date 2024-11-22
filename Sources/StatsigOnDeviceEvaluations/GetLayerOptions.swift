import Foundation

@objc public class GetLayerOptions: NSObject {
    @objc public var userPersistedValues: UserPersistedValues?
    @objc public var disableExposureLogging: Bool = false
    
    static func disabledExposures() -> GetLayerOptions {
        let opts = GetLayerOptions()
        opts.disableExposureLogging = true
        return opts
    }
}
