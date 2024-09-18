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
        public static let eventQueueMaxSize = 20
        public static let eventQueueInternalMs = 10_000.0
        public static let configSpecAPI = "https://api.statsigcdn.com/v1/download_config_specs/"
        public static let eventLoggingAPI = "https://events.statsigapi.net/v1/rgstr"
    }

    /**
     The maximum number of events to batch before flushing logs to the server.
     */
    @objc public var eventQueueMaxSize: Int = Defaults.eventQueueMaxSize

    /**
     How frequently to flush queued logs.
     */
    @objc public var eventQueueInternalMs: Double = Defaults.eventQueueInternalMs

    /**
     The API where all events are sent.
     */
    @objc public var eventLoggingAPI: String = Defaults.eventLoggingAPI

    /**
     The API used to fetch the latest configurations.
     */
    @objc public var configSpecAPI: String = Defaults.configSpecAPI

    /**
     An object you can use to set environment variables that apply to all of your users in the same session and will be used for targeting purposes.
     */
    @objc public var environment: StatsigEnvironment

    /**
     If you want to ensure that a user's variant stays consistent while an experiment is running, regardless of changes to allocation or targeting, you can provided a class that implements the UserPersistentStorageProvider.
     */
    @objc public var userPersistentStorage: UserPersistentStorageProvider?

    /**
     * Plugin to override SDK evaluations
     */
    @objc public var overrideAdapter: OverrideAdapter?

    public override init() {
        environment = StatsigEnvironment()
    }
}
