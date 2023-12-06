import Foundation

public protocol StatsigEventValue {}

extension String: StatsigEventValue {}
extension Double: StatsigEventValue {}
extension Int: StatsigEventValue {}

@objc public class StatsigEvent: NSObject {
    let eventName: String
    let value: StatsigEventValue?
    let metadata: [String: String]?

    public init(
        eventName: String,
        value: StatsigEventValue? = nil,
        metadata: [String: String]? = nil
    ) {
        self.eventName = eventName
        self.value = value
        self.metadata = metadata
    }

    @objc public static func event(
        withName eventName: String,
        metadata: [String: String]
    ) -> StatsigEvent {
        StatsigEvent(eventName: eventName, value: nil, metadata: metadata)
    }

    @objc public static func event(
        withName eventName: String
    ) -> StatsigEvent {
        StatsigEvent(eventName: eventName, value: nil, metadata: nil)
    }

    @objc public static func event(
        withName eventName: String,
        stringValue value: String?,
        metadata: [String: String]?
    ) -> StatsigEvent {
        StatsigEvent(eventName: eventName, value: value, metadata: metadata)
    }

    @objc public static func event(
        withName eventName: String,
        doubleValue value: Double,
        metadata: [String: String]?
    ) -> StatsigEvent {
        StatsigEvent(eventName: eventName, value: value, metadata: metadata)
    }

    @objc public static func event(
        withName eventName: String,
        intValue value: Int,
        metadata: [String: String]?
    ) -> StatsigEvent {
        StatsigEvent(eventName: eventName, value: value, metadata: metadata)
    }
}
