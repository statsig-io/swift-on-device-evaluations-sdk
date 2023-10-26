import Foundation
import StatsigInternal

@objc public class StatsigUser: StatsigUserInternal {
    var statsigEnvironment: [String: String] = [:]
    var deviceEnvironment: [String: String?] = [:]

    func toDictionary(forLogging: Bool) -> [String: Any?] {
        var dict = [String: Any?]()

        dict["userID"] = self.userID

        if !customIDs.isEmpty {
            dict["customIDs"] = customIDs
        }

        dict["email"] = self.email
        dict["ip"] = self.ip
        dict["country"] = self.country
        dict["locale"] = self.locale
        dict["appVersion"] = self.appVersion

        dict["statsigEnvironment"] = self.statsigEnvironment

        if !self.custom.values.isEmpty {
            dict["custom"] = self.custom.values
        }

        if !forLogging && !self.privateAttributes.values.isEmpty {
            dict["privateAttributes"] = self.privateAttributes.values
        }
        return dict
    }

    @objc(toDictionary)
    public func toDictionaryObjC() -> NSDictionary {
        return toDictionary(forLogging: false) as NSDictionary
    }

    func getCacheKey() -> String {
        var key = userID

        for (idType, idValue) in customIDs {
            key += "\(idType)\(idValue)"
        }

        return key
    }

    func getFullUserHash() -> String? {
        let dict = toDictionary(forLogging: false)
        let sorted = getSortedPairsString(dict)
        return sorted.djb2()
    }

    func setStableID(_ overrideStableID: String) {
        self.deviceEnvironment = DeviceEnvironment().get(overrideStableID)
    }

    fileprivate func getSortedPairsString(_ dictionary: [String: Any?]) -> String {
        let sortedPairs = dictionary.sorted { $0.key < $1.key }
        var sortedResult = [String]()
        for (key, value) in sortedPairs {
            if let nestedDictionary = value as? [String: Any?] {
                let sortedNested = getSortedPairsString(nestedDictionary)
                sortedResult.append("\(key):\(sortedNested)")
            } else {
                sortedResult.append("\(key):\(value ?? "")")
            }
        }
        return sortedResult.joined(separator: ",")
    }
}
