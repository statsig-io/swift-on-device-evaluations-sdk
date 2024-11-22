import Foundation

@objc public enum StatsigErrorCode: Int {
    case uninitialized = 1
    case noUserProvided
    case invalidSyncInterval
    case backgroundSyncFailure
    case unsupportedConfiguration
    case typedInvalidSubclass
    case typedInvalidGroup
    case typedInvalidValue
}

@objc public enum StatsigClientEvent: Int, CustomStringConvertible {
    case eventsFlushed
    case valuesUpdated
    case error

    public var description : String {
        switch self {
        case .eventsFlushed: return "eventsFlushed"
        case .valuesUpdated: return "valuesUpdated"
        case .error: return "error"
        }
    }
}

@objc public protocol StatsigListening: AnyObject {
    @objc(onStatsigClientEvent:withEventData:)
    func onStatsigClientEvent(_ event: StatsigClientEvent, _ eventData: [String: Any]) -> Void
}

class StatsigClientEventEmitter {
    private var listeners: [StatsigListening] = []

    public func addListener(_ listener: StatsigListening) {
        listeners.append(listener)
    }

    public func removeListener(_ listener: StatsigListening) {
        self.listeners.removeAll { entry in
            return entry === listener
        }
    }

    public func emit(_ event: StatsigClientEvent, _ data: [String: Any]) {
        for listener in listeners {
            listener.onStatsigClientEvent(event, data)
        }
    }

    public func emitError(_ message: String, _ code: StatsigErrorCode) {
        emit(.error, ["message": message, "errorCode": code, "rawErrorCode": code.rawValue])
        print("[Statsig]: \(message)")
    }
}
