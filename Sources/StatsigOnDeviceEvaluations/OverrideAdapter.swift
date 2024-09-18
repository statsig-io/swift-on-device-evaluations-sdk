import Foundation

@objc public protocol OverrideAdapter {
    func getGate(_ user: StatsigUser, _ name: String, _ options: GetFeatureGateOptions?) -> FeatureGate?
    func getConfig(_ user: StatsigUser, _ name: String, _ options: GetDynamicConfigOptions?) -> DynamicConfig?
    func getExperiment(_ user: StatsigUser, _ name: String, _ options: GetExperimentOptions?) -> Experiment?
    func getLayer(_ user: StatsigUser, _ name: String, _ options: GetLayerOptions?) -> Layer?
}
