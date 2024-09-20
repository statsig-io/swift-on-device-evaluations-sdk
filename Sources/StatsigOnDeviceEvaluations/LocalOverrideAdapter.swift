import Foundation

@objc public class LocalOverrideAdapter : NSObject, OverrideAdapter {
    class OverrideStore {
        var gates = [String: FeatureGate]()
        var configs = [String: DynamicConfig]()
        var experiments = [String: Experiment]()
        var layers = [String: Layer]()
    }
    private var store: [String: OverrideStore]
    private var idType: String
    
    public override init() {
        self.store = [String: OverrideStore]()
        self.idType = "userID"
    }
    
    @objc(initWithIdType:)
    public init(_ idType: String = "userID") {
        self.store = [String: OverrideStore]()
        self.idType = idType
    }

    // MARK: Gates
    
    public func getGate(_ user: StatsigUser, _ name: String, _ options: GetFeatureGateOptions?) -> FeatureGate? {
        return store[getUserKey(user)]?.gates[name]
    }
    
    @objc(setGateForUser:gate:)
    public func setGate(_ user: StatsigUser, _ gate: FeatureGate) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.gates[gate.name] = gate
    }
    
    @objc(removeGateForUser:name:)
    public func removeGate(_ user: StatsigUser, _ name: String) {
        store[getUserKey(user)]?.gates[name] = nil
    }
    
    // MARK: Dynamic Configs

    public func getDynamicConfig(_ user: StatsigUser, _ name: String, _ options: GetDynamicConfigOptions?) -> DynamicConfig? {
        return store[getUserKey(user)]?.configs[name]
    }
    
    @objc(setDynamicConfigForUser:config:)
    public func setDynamicConfig(_ user: StatsigUser, _ config: DynamicConfig) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.configs[config.name] = config
    }
    
    @objc(removeDynamicConfigForUser:name:)
    public func removeDynamicConfig(_ user: StatsigUser, _ name: String) {
        store[getUserKey(user)]?.configs[name] = nil
    }

    // MARK: Experiments
    
    public func getExperiment(_ user: StatsigUser, _ name: String, _ options: GetExperimentOptions?) -> Experiment? {
        return store[getUserKey(user)]?.experiments[name]
    }
    
    @objc(setExperimentForUser:experiment:)
    public func setExperiment(_ user: StatsigUser, _ experiment: Experiment) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.experiments[experiment.name] = experiment
    }
    
    @objc(removeExperimentForUser:name:)
    public func removeExperiment(_ user: StatsigUser, _ name: String) {
        store[getUserKey(user)]?.experiments[name] = nil
    }
    
    // MARK: Layers

    public func getLayer(_ user: StatsigUser, _ name: String, _ options: GetLayerOptions?) -> Layer? {
        return store[getUserKey(user)]?.layers[name]
    }
    
    @objc(setLayer:layer:)
    public func setLayer(_ user: StatsigUser, _ layer: Layer) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.layers[layer.name] = layer
    }

    @objc(removeLayerForUser:name:)
    public func removeLayer(_ user: StatsigUser, _ name: String) {
        store[getUserKey(user)]?.layers[name] = nil
    }
    
    // MARK: Private
    
    private func getUserKey(_ user: StatsigUser) -> String {
        return StatsigUserInternal(user: user, environment: nil).getUnitID(self.idType) ?? ""
    }
}
