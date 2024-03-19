import Foundation

public typealias UserPersistedValues = [String: [String: Any]]

@objc public protocol UserPersistentStorageProvider: AnyObject {
    func delete(_ key: String, _ experiment: String)
    func save(_ key: String, _ experiment: String, _ data: String)
    func load(_ key: String) -> UserPersistedValues
    func loadAsync(_ key: String, _ completion: @escaping (UserPersistedValues) -> Void)
}


// MARK: Internal

func getStorageKey(user: StatsigUserInternal, idType: String) -> String {
    return "\(user.getUnitID(idType) ?? ""):\(idType)"
}

extension EvaluationResult {
    static func sticky(_ value: [String: Any]) -> EvaluationResult? {
        guard
            let ruleID = value["rule_id"] as? String,
            let boolValue = value["value"] as? Bool,
            let json = value["json_value"] as? [String: Any],
            let jsonString = json.toJsonString(),
            let jsonValue = try? JSONDecoder().decode(JsonValue.self, from: jsonString.data(using: .utf8)!)
        else {
            return nil
        }

        let secondaryExposures = value["secondary_exposures"] as? [[String: String]] ?? []
        let groupName = value["group_name"] as? String
        let explicitParameters: [String]? = value["explicit_parameters"] as? [String]
        let configDelegate: String? = value["config_delegate"] as? String
        let undelegatedSecondaryExposures: [[String: String]]? = value["undelegated_secondary_exposures"] as? [[String: String]]

        return EvaluationResult(
            ruleID: ruleID,
            boolValue: boolValue,
            jsonValue: jsonValue,
            secondaryExposures: secondaryExposures,
            undelegatedSecondaryExposures: undelegatedSecondaryExposures,
            isExperimentGroup: true,
            groupName: groupName,
            explicitParameters: explicitParameters,
            configDelegate: configDelegate
        )
    }
}

extension UserPersistentStorageProvider {
    func getStickyValue(
        _ user: StatsigUserInternal,
        _ spec: Spec,
        _ userPersistedValues: UserPersistedValues
    ) -> DetailedEvaluation? {
        if let value = userPersistedValues[spec.name],
           let evaluation = EvaluationResult.sticky(value) {
            return (
                evaluation: evaluation,
                details: .sticky(value["time"] as? Int64 ?? 0)
            )
        }

        return nil
    }

    func saveStickyValue(
        _ user: StatsigUserInternal,
        _ spec: Spec,
        _ detailedEvaluation: DetailedEvaluation
    ) {
        if (!detailedEvaluation.evaluation.isExperimentGroup) {
            return
        }

        let evaluation = detailedEvaluation.evaluation
        let key = getStorageKey(user: user, idType: spec.idType)
        let data: [String: Any?] = [
            "value": evaluation.boolValue,
            "rule_id": evaluation.ruleID,
            "json_value": evaluation.jsonValue?.serializeToDictionary(),
            "secondary_exposures": evaluation.secondaryExposures,
            "explicit_parameters": evaluation.explicitParameters,
            "config_delegate": evaluation.configDelegate,
            "undelegated_secondary_exposures": evaluation.undelegatedSecondaryExposures,
            "group_name": evaluation.groupName,
            "time": detailedEvaluation.details.lcut,
        ]

        guard let json = data.toJsonString() else {
            return
        }

        save(key, spec.name, json)
    }

    func deleteStickyValue(
        _ user: StatsigUserInternal,
        _ spec: Spec
    ) {
        let key = getStorageKey(user: user, idType: spec.idType)
        var latest = load(key)
        latest.removeValue(forKey: spec.name)
        delete(key, spec.name)
    }
}
