import Foundation


@objc public class StatsigOptions: NSObject {
    @objc public class Defaults: NSObject {
        public static let maxEventQueueSize = 20
    }

    /**
     The maximum number of events to batch before flushing logs to the server.
     */
    @objc public var maxEventQueueSize: Int = Defaults.maxEventQueueSize

    public override init() {}
}
