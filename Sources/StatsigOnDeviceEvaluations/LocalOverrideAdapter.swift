import Foundation

public class LocalOverrideAdapter : OverrideAdapter {
    class OverrideStore {
        var gates = [String: FeatureGate]()
        var configs = [String: DynamicConfig]()
        var experiments = [String: Experiment]()
        var layers = [String: Layer]()
    }
    private var store: [String: OverrideStore]
    private var idType: String

    init(
        _ store: [String : OverrideStore] = [String: OverrideStore](),
        _ idType: String = "userID"
    ) {
        self.store = store
        self.idType = idType
    }

    public func getGate(_ user: StatsigUser, _ name: String, _ options: GetFeatureGateOptions?) -> FeatureGate? {
        return store[getUserKey(user)]?.gates[name]
    }
    
    public func setGate(_ user: StatsigUser, _ name: String, _ value: FeatureGate) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.gates[name] = value
    }
    
    public func removeGate(_ user: StatsigUser, _ name: String) {
        store[getUserKey(user)]?.gates[name] = nil
    }

    public func getConfig(_ user: StatsigUser, _ name: String, _ options: GetDynamicConfigOptions?) -> DynamicConfig? {
        return store[getUserKey(user)]?.configs[name]
    }
    
    public func setConfig(_ user: StatsigUser, _ name: String, _ value: DynamicConfig) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.configs[name] = value
    }
    
    public func removeConfig(_ user: StatsigUser, _ name: String, _ value: DynamicConfig) {
        store[getUserKey(user)]?.configs[name] = nil
    }

    public func getExperiment(_ user: StatsigUser, _ name: String, _ options: GetExperimentOptions?) -> Experiment? {
        return store[getUserKey(user)]?.experiments[name]
    }
    
    public func setExperiment(_ user: StatsigUser, _ name: String, _ value: Experiment) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.experiments[name] = value
    }
    
    public func removeExperiment(_ user: StatsigUser, _ name: String, _ value: Experiment) {
        store[getUserKey(user)]?.experiments[name] = nil
    }

    public func getLayer(_ user: StatsigUser, _ name: String, _ options: GetLayerOptions?) -> Layer? {
        return store[getUserKey(user)]?.layers[name]
    }
    
    public func setLayer(_ user: StatsigUser, _ name: String, _ value: Layer) {
        if (store[getUserKey(user)] == nil) {
            store[getUserKey(user)] = OverrideStore()
        }
        store[getUserKey(user)]?.layers[name] = value
    }
    
    public func removeLayer(_ user: StatsigUser, _ name: String, _ value: Layer) {
        store[getUserKey(user)]?.layers[name] = nil
    }
    
    private func getUserKey(_ user: StatsigUser) -> String {
        return StatsigUserInternal(user: user, environment: nil).getUnitID(self.idType) ?? ""
    }
}
