import Foundation

@objc public class StatsigEnvironment: NSObject {
    /**
     The environment tier, eg 'production', 'staging' or 'development'
     */
    @objc public var tier: String?

    public override init() {}
}

@objc public class StatsigOptions: NSObject {
    @objc public class Defaults: NSObject {
        public static let maxEventQueueSize = 20
        public static let configSpecAPI = "https://api.statsigcdn.com/v1/download_config_specs/"
        public static let eventLoggingAPI = "https://events.statsigapi.net/v1/rgstr"
    }

    /**
     The maximum number of events to batch before flushing logs to the server.
     */
    @objc public var maxEventQueueSize: Int = Defaults.maxEventQueueSize

    /**
     The API used to fetch the latest configurations.
     */
    @objc public var configSpecAPI: String = Defaults.configSpecAPI

    /**
     The API where all events are sent.
     */
    @objc public var eventLoggingAPI: String = Defaults.eventLoggingAPI

    /**
     An object you can use to set environment variables that apply to all of your users in the same session and will be used for targeting purposes.
     */
    @objc public var environment: StatsigEnvironment

    public override init() {
        environment = StatsigEnvironment()
    }
}
