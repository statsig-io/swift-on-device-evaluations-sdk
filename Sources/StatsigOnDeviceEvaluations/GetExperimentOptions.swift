import Foundation

@objc public class GetExperimentOptions: NSObject {
    @objc public var userPersistedValues: UserPersistedValues?
    @objc public var disableExposureLogging: Bool = false
    
    static func disabledExposures() -> GetExperimentOptions {
        let opts = GetExperimentOptions()
        opts.disableExposureLogging = true
        return opts
    }
}
