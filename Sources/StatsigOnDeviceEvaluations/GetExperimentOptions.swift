import Foundation

@objc public class GetExperimentOptions: NSObject {
    @objc public var userPersistedValues: UserPersistedValues?
    @objc public var disableExposureLogging: Bool = false
}
