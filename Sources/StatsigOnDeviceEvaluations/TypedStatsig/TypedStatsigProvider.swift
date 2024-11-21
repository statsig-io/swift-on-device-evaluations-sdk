import Foundation

class MemoStore {
    var gates: [String: FeatureGate] = [:]
    var experiments: [String: any TypedExperiment] = [:]
}

@objc
open class TypedStatsigProvider: NSObject {
    weak var client: Statsig?
    var memo = MemoStore()
    
    @objc(checkGate:forUser:)
    open func checkGate(_ name: TypedGateName, _ user: StatsigUser? = nil) -> Bool {
        return getFeatureGate(name, user).value
    }
    
    @objc(getFeatureGate:forUser:)
    open func getFeatureGate(_ name: TypedGateName, _ user: StatsigUser? = nil) -> FeatureGate {
        guard let (client, user) = validate(user, name.value) else {
            return FeatureGate.empty(name.value, .empty())
        }

        if let found = tryGetMemoFeatureGate(name, user) {
            return found
        }
        
        let gate = client.getFeatureGate(name.value, user)
        return tryMemoizeFeatureGate(name, gate, user)
    }
    
    open func getExperiment<T: TypedExperiment>(
        _ type: T.Type,
        _ user: StatsigUser? = nil
    ) -> T {
        guard let (client, user) = validate(user, type.name) else {
            return T.init()
        }

        if let found = tryGetMemoExperiment(type, user) {
            return found
        }
        
        let experiment = client.getExperiment(type.name, user)
        guard let groupName = experiment.groupName else {
            return tryMemoizeExperiment(T.init(), user)
        }
        
        guard let group = T.GroupNameType.init(rawValue:groupName) else {
            self.client?.emitter.emitError("Failed to convert group name '\(groupName)' to \(T.GroupNameType.self)")
            return tryMemoizeExperiment(T.init(), user)
        }
        
        var value: T.ValueType? = nil
        if let raw = experiment.rawValue {
            let decoder = JSONDecoder()
            value = try? decoder.decode(T.ValueType.self, from: raw)
        }

        return tryMemoizeExperiment(
            T.init(groupName: group, value: value),
            user
        )
    }
    
    open func bind(_ client: Statsig, _ options: StatsigOptions?) -> Void {
        self.client = client
        self.memo = MemoStore()
    }
    
    private func validate(
        _ user: StatsigUser?,
        _ name: String,
        caller: String = #function
    ) -> (Statsig, StatsigUser)? {
        guard let client = client, let context = client.context else {
            let message = "Must initialize Statsig first"
            
            if client == nil {
                print("[Statsig]: \(message)")
            } else {
                self.client?.emitter.emitError("Must initialize Statsig first")
            }
            return nil
        }
        
        guard let user = user ?? context.globalUser else {
            client.emitter.emitError(
                "No user given when calling Statsig.typed.\(caller) for `\(name)`."
                + " Please provide a StatsigUser or call setGlobalUser."
            )
            return nil
        }
        
        return (client, user)
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
        return memo.experiments[key] as? T
    }
    
    private func tryMemoizeExperiment<T: TypedExperiment>(
        _ experiment: T,
        _ user: StatsigUser
    ) -> T {
        if !experiment.isMemoizable {
            return experiment
        }
        
        let key = getMemoKey(user, experiment.memoUnitIdType, experiment.name)
        memo.experiments[key] = experiment
        return experiment
    }
    
    private func tryGetMemoFeatureGate(
        _ name: TypedGateName,
        _ user: StatsigUser
    ) -> FeatureGate? {
        if !name.isMemoizable {
            return nil
        }
        
        let key = getMemoKey(user, name.memoUnitIdType, name.value)
        return memo.gates[key]
    }

    private func tryMemoizeFeatureGate(
        _ name: TypedGateName,
        _ gate: FeatureGate,
        _ user: StatsigUser
    ) -> FeatureGate {
        if !name.isMemoizable {
            return gate
        }
        
        let key = getMemoKey(user, name.memoUnitIdType, name.value)
        memo.gates[key] = gate
        return gate
    }
    
    private func getMemoKey(_ user: StatsigUser, _ idType: String, _ name: String) -> String {
        let idValue = user.getUnitID(idType) ?? "<NONE>"
        return "\(idType):\(idValue):\(name)"
    }
}

