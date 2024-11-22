import Foundation

class MemoStore {
    var gates: [String: FeatureGate] = [:]
    var experiments: [String: Any] = [:]
}

@objc
open class TypedStatsigProvider: NSObject {
    weak var client: Statsig?
    var memo = MemoStore()
    
    @objc(checkGate:forUser:options:)
    open func checkGate(
        _ name: TypedGateName,
        _ user: StatsigUser? = nil,
        _ options: GetFeatureGateOptions? = nil
    ) -> Bool {
        return getFeatureGate(name, user, options).value
    }
    
    @objc(getFeatureGate:forUser:options:)
    open func getFeatureGate(
        _ name: TypedGateName,
        _ user: StatsigUser? = nil,
        _ options: GetFeatureGateOptions? = nil
    ) -> FeatureGate {
        guard let (client, user) = validate(user, name.value) else {
            return FeatureGate.empty(name.value, .empty())
        }

        if let found = tryGetMemoFeatureGate(name, user) {
            return found
        }
        
        let gate = client.getFeatureGate(name.value, user, options)
        return tryMemoizeFeatureGate(name, gate, user)
    }
    
    open func getExperiment<G: TypedGroupName, V: Decodable, E: TypedExperiment<G, V>>(
        _ experiment: E,
        _ user: StatsigUser? = nil,
        _ options: GetExperimentOptions? = nil
    ) -> E {
        let result = experiment.new()
        
        guard let (client, user) = validate(user, experiment.name) else {
            return result
        }
        
        if result.name == InvalidTypedExperimentSubclassError {
            let err = "TypedExperiment '\(E.self)' does not implement init"
            self.client?.emitter.emitError(err, .typedInvalidSubclass)
            return result
        }
        
        if let found = tryGetMemoExperiment(experiment, user) {
            return found
        }
        
        let rawExperiment = client.getExperiment(experiment.name, user, options)

        result.trySetGroupFromString(rawExperiment.groupName)
        result.trySetValueFromData(rawExperiment.rawValue)

        if let rawGroupName = rawExperiment.groupName, result.group == nil {
            let err = "Failed to convert group name '\(rawGroupName)' to type '\(G.self)'"
            self.client?.emitter.emitError(err, .typedInvalidGroup)
        }

        if V.self != TypedNoValue.self, let rawValue = rawExperiment.rawValue, result.value == nil {
            let json = String(data: rawValue, encoding: .utf8) ?? "<UNKNOWN>"
            let subjson = json.prefix(100)
            let err = "Failed to deserialize json value '\(subjson)' to type '\(V.self)'"
            self.client?.emitter.emitError(err, .typedInvalidValue)
        }

        return tryMemoizeExperiment(result, user)
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
                self.client?.emitter.emitError("Must initialize Statsig first", .uninitialized)
            }
            return nil
        }
        
        guard let user = user ?? context.globalUser else {
            client.emitter.emitError(
                "No user given when calling Statsig.typed.\(caller) for `\(name)`."
                + " Please provide a StatsigUser or call setGlobalUser.",
                .noUserProvided
            )
            return nil
        }
        
        return (client, user)
    }
}


// MARK: Memoization
extension TypedStatsigProvider {
    private func tryGetMemoExperiment<G: TypedGroupName, V: Decodable, E: TypedExperiment<G, V>>(
        _ experiment: E,
        _ user: StatsigUser
    ) -> E? {
        if !experiment.isMemoizable {
            return nil
        }
        
        let key = getMemoKey(user, experiment.memoUnitIdType, experiment.name)
        return (memo.experiments[key] as? E)?.clone()
    }
    
    private func tryMemoizeExperiment<G: TypedGroupName, V: Decodable, E: TypedExperiment<G, V>>(
        _ experiment: E,
        _ user: StatsigUser
    ) -> E {
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


