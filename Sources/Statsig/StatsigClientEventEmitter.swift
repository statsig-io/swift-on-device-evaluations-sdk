import Foundation

@objc public enum StatsigClientEvent: Int {
    case eventsFlushed
    case valuesUpdated
    case valuesUpdateError
}

typealias StatsigListeningID = String

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
}
