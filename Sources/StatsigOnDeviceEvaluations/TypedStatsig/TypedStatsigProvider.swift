import Foundation

@objc
open class TypedStatsigProvider: NSObject {
    var client: Statsig?
    var memoedExperiments: [String: any TypedExperiment] = [:]
    
    @objc(checkGate:forUser:)
    open func checkGate(_ key: TypedGateName, _ user: StatsigUser? = nil) -> Bool {
        return client?.checkGate(key.value, user) == true
    }
    
    @objc(getFeatureGate:forUser:)
    open func getFeatureGate(_ key: TypedGateName, _ user: StatsigUser? = nil) -> FeatureGate {
        if let client = client {
            return client.getFeatureGate(key.value, user)
        }
        
        return FeatureGate.empty(key.value, .empty())
    }
    
    open func getExperiment<T: TypedExperiment>(
        _ type: T.Type,
        _ user: StatsigUser? = nil
    ) -> T {
        guard let client = client, let context = client.context else {
            self.client?.emitter.emitError("Must initialize Statsig first")
            return T.init()
        }
        
        guard let user = user ?? context.globalUser else {
            client.emitter.emitError("No user given when calling Statsig.typed.getExperiment(::)."
                              + " Please provide a StatsigUser or call setGlobalUser.")
            return T.init()
        }
        
        if let found = tryGetMemoExperiment(type, user) {
            return found
        }

        let experiment = client.getExperiment(type.name, user)
        guard let groupName = experiment.groupName else {
            return tryMemoize(T.init(), user)
        }
        
        guard let group = T.GroupNameType.init(rawValue:groupName) else {
            self.client?.emitter.emitError("Failed to convert group name '\(groupName)' to \(T.GroupNameType.self)")
            return tryMemoize(T.init(), user)
        }
        
        var value: T.ValueType? = nil
        if let raw = experiment.rawValue {
            let decoder = JSONDecoder()
            value = try? decoder.decode(T.ValueType.self, from: raw)
        }
        
        return tryMemoize(
            T.init(groupName: group, value: value),
            user
        )
    }
    
    open func bind(_ client: Statsig, _ options: StatsigOptions?) -> Void {
        self.client = client
        self.memoedExperiments = [:]
    }
}


// MARK: Memoization
extension TypedStatsigProvider {
    private func tryGetMemoExperiment<T: TypedExperiment>(
        _ type: T.Type,
        _ user: StatsigUser
    ) -> T? {
        if !type.isMemoizable {
            return nil
        }
        
        let key = getMemoKey(user, type.memoUnitIdType, type.name)
        return memoedExperiments[key] as? T
    }
    
    private func tryMemoize<T: TypedExperiment>(
        _ instance: T,
        _ user: StatsigUser
    ) -> T {
        if !instance.isMemoizable {
            return instance
        }

        let key = getMemoKey(user, instance.memoUnitIdType, instance.name)
        memoedExperiments[key] = instance
        return instance
    }
    
    private func getMemoKey(_ user: StatsigUser, _ idType: String, _ name: String) -> String {
        let idValue = user.getUnitID(idType) ?? "<NONE>"
        return "\(idType):\(idValue):\(name)"
    }
}

