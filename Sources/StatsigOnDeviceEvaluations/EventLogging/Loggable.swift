import Foundation

protocol Loggable {
    func toLoggable() -> [String: Any]
}

extension StatsigUserValueMap: Loggable {
    func toLoggable() -> [String : Any] {
        return self.values
    }
}

extension StatsigUserInternal: Loggable {
    func toLoggable() -> [String : Any] {
        var result: [String : Any?] = [
            "userID" : user.userID,
            "email": user.email,
            "ip": user.ip,
            "country": user.country,
            "locale": user.locale,
            "appVersion": user.appVersion,
            "customIDs" : user.customIDs,
            "userAgent": user.userAgent
        ]

        if !user.custom.values.isEmpty {
            result["custom"] = user.custom.toLoggable()
        }

        if !user.customIDs.isEmpty {
            result["customIDs"] = user.customIDs
        }

        if let env = user.environment ?? environment, let tier = env.tier {
            result["statsigEnvironment"] = ["tier": tier]
        }

        return result.compactMapValues { $0 }
    }
}

extension StatsigEventInternal: Loggable {
    func toLoggable() -> [String : Any] {
        var result: [String: Any] = [
            "eventName": eventName,
            "user": user.toLoggable(),
            "time": time,
            "statsigMetadata": StatsigMetadata.get().toLoggable(),
        ]

        if let value = value {
            result["value"] = value
        }

        if let metadata = metadata {
            result["metadata"] = metadata
        }

        if let exposures = secondaryExposures {
            result["secondaryExposures"] = exposures
        }

        return result
    }
}
