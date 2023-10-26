extension StatsigUser {
    internal func getUnitID(_ type: String) -> String? {
        let lowered = type.lowercased()

        if lowered == "userid" {
            return userID
        }

        return customIDs[type] ?? customIDs[lowered]
    }

    internal func getFromEnvironment(_ field: String?) -> JsonValue? {
        return nil
    }

    internal func getUserValue(_ field: String?) -> JsonValue? {
        guard let field else {
            return nil
        }

        let lowered = field.lowercased()
        if let strValue = getUserValueString(lowered) {
            return .string(strValue)
        }

        if let value = custom[field] ?? custom[lowered] {
            return value
        }

        if let value = privateAttributes[field] ?? privateAttributes[lowered] {
            return value
        }

        return nil
    }

    private func getUserValueString(_ field: String) -> String? {
        switch field {
        case "userid", "user_id": return self.userID
        case "email": return self.email
        case "ip": return self.ip
        case "useragent", "user_agent": return self.userAgent
        case "country": return self.country
        case "locale": return self.locale
        case "appversion", "app_version": return self.appVersion
        default: return nil
        }
    }
}

extension StatsigUserValueMap {
    subscript(key: String) -> JsonValue? {
        get {
            return JsonValue(self.values[key])
        }
    }
}
