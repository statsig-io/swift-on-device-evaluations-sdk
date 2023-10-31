import Foundation

@objc
open class StatsigUserValueMap: NSObject {
    public var values: [String: StatsigUserValue]

    public init(_ values: [String : StatsigUserValue] = [:]) {
        self.values = values
    }

    @objc
    public override init() {
        self.values = [:]
    }

    @objc(setString:forKey:)
    public func set(value: String, forKey key: String) {
        values[key] = value
    }

    @objc(setBoolean:forKey:)
    public func set(value: Bool, forKey key: String) {
        values[key] = value
    }

    @objc(setInteger:forKey:)
    public func set(value: Int, forKey key: String) {
        values[key] = value
    }

    @objc(setDouble:forKey:)
    public func set(value: Double, forKey key: String) {
        values[key] = value
    }

    @objc(setStrings:forKey:)
    public func set(value: [String], forKey key: String) {
        values[key] = value
    }
}

public protocol StatsigUserValue {}

extension String: StatsigUserValue {}
extension Double: StatsigUserValue {}
extension Int: StatsigUserValue {}
extension UInt: StatsigUserValue {}
extension Bool: StatsigUserValue {}
extension Array<String>: StatsigUserValue {}
