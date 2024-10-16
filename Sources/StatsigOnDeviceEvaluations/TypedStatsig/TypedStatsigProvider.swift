import Foundation

@objc
open class TypedStatsigProvider: NSObject {
    var client: Statsig?

    @objc(checkGate:forUser:)
    open func checkGate(_ key: TypedGateName, _ user: StatsigUser) -> Bool {
        return client?.checkGate(key.value, user) == true
    }

    @objc(getFeatureGate:forUser:)
    open func getFeatureGate(_ key: TypedGateName, _ user: StatsigUser) -> FeatureGate {
        if let client = client {
            return client.getFeatureGate(key.value, user)
        }

        return FeatureGate.empty(key.value, .empty())
    }

    open func getExperiment<T: TypedExperiment>(_ type: T.Type, _ user: StatsigUser) -> T {
        guard
            let exp = self.client?.getExperiment(type.name, user),
            let groupName = exp.groupName
        else {
            return T.init()
        }

        guard let group = T.GroupNameType.init(rawValue:groupName) else {
            self.client?.emitter.emitError("Failed to convert group name '\(groupName)' to \(T.GroupNameType.self)")
            return T.init()
        }

        var value: T.ValueType? = nil
        if let raw = exp.rawValue {
            let decoder = JSONDecoder()
            value = try? decoder.decode(T.ValueType.self, from: raw)
        }

        return T.init(groupName: group, value: value)
    }

    open func bind(_ client: Statsig, _ options: StatsigOptions?) -> Void {
        self.client = client
    }
}
