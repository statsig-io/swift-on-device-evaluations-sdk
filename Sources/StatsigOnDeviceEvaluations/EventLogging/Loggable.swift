import Foundation

protocol Loggable {
    func toLoggable() -> [String: Any]
}

extension StatsigUserValueMap: Loggable {
    func toLoggable() -> [String : Any] {
        return self.values
    }
}

extension StatsigUser: Loggable {
    func toLoggable() -> [String : Any] {
        var result: [String : Any?] = [
            "userID" : userID,
            "email": email,
            "ip": ip,
            "country": country,
            "locale": locale,
            "appVersion": appVersion,
            "customIDs" : customIDs
        ]

        if !custom.values.isEmpty {
            result["custom"] = custom.toLoggable()
        }

        if !customIDs.isEmpty {
            result["customIDs"] = customIDs
        }

        return result.compactMapValues { $0 }
    }
}

extension StatsigEventInternal: Loggable {
    func toLoggable() -> [String : Any] {
        var result: [String: Any] = [
            "eventName": event.eventName,
            "user": user.toLoggable(),
            "time": time,
            //            "statsigMetadata": statsigMetadata,
            //            "allocatedExperimentHash": allocatedExperimentHash,
        ]

        if let value = event.value {
            result["value"] = value
        }

        if let metadata = event.metadata {
            result["metadata"] = metadata
        }

        if let exposures = secondaryExposures {
            result["secondaryExposures"] = exposures
        }

        return result
    }
}
