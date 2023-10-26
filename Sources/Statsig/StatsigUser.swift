import Foundation

@objc open class StatsigUser: NSObject {
    @objc public var userID: String = ""
    @objc public var customIDs = [String: String]()

    @objc public var email: String?
    @objc public var ip: String?
    @objc public var userAgent: String?
    @objc public var country: String?
    @objc public var locale: String?
    @objc public var appVersion: String?

    @objc public lazy var custom: StatsigUserValueMap = {
        StatsigUserValueMap()
    }()

    @objc public lazy var privateAttributes: StatsigUserValueMap = {
        StatsigUserValueMap()
    }()

    internal var environment: [String: String]?

    public init(userID: String) {
        self.userID = userID
    }

    public init(customIDs: [String: String]) {
        self.customIDs = customIDs
    }

    public required init(
        userID: String,
        customIDs: [String: String] = [:],
        email: String? = nil,
        ip: String? = nil,
        userAgent: String? = nil,
        country: String? = nil,
        locale: String? = nil,
        appVersion: String? = nil,
        custom: [String: StatsigUserValue]? = nil,
        privateAttributes: [String: StatsigUserValue]? = nil
    ) {
        self.userID = userID
        self.customIDs = customIDs
        self.email = email
        self.ip = ip
        self.userAgent = userAgent
        self.country = country
        self.locale = locale
        self.appVersion = appVersion
    }

    @objc
    public static func userWith(userID: String) -> Self {
        return Self.init(userID: userID, customIDs: [:])
    }

    @objc
    public static func userWith(customIDs: [String: String]) -> Self {
        return Self.init(userID: "", customIDs: customIDs)
    }
}
