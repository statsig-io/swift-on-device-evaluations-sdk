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
        let isExperimentGroup = value["is_experiment_group"] as? Bool == true
        let groupName = value["group_name"] as? String

        return .specResult(
            ruleID: ruleID,
            boolValue: boolValue,
            jsonValue: jsonValue,
            secondaryExposures: secondaryExposures,
            isExperimentGroup: isExperimentGroup,
            groupName: groupName
        )
    }
}

extension UserPersistentStorageProvider {
    func getStickyValue(
        _ user: StatsigUserInternal,
        _ specAndSourceInfo: SpecAndSourceInfo,
        _ userPersistedValues: UserPersistedValues?
    ) -> DetailedEvaluation? {
        guard let spec = specAndSourceInfo.spec else {
            return nil
        }

        if spec.isActive != true || userPersistedValues == nil {
            let key = getStorageKey(user: user, idType: spec.idType)
            let latest = load(key)
            if latest[spec.name] != nil {
                delete(key, spec.name)
            }
            return nil
        }

        if let value = userPersistedValues?[spec.name],
           let evaluation = EvaluationResult.sticky(value) {
            return (
                evaluation: evaluation,
                details: .sticky(value["time"] as? Int ?? 0)
            )
        }

        return nil
    }

    func saveStickyValueIfNeeded(
        _ user: StatsigUserInternal,
        _ specAndSourceInfo: SpecAndSourceInfo,
        _ detailedEvaluation: DetailedEvaluation
    ) {
        guard
            let spec = specAndSourceInfo.spec,
            spec.isActive == true,
            detailedEvaluation.evaluation.isExperimentGroup
        else {
            return
        }

        let evaluation = detailedEvaluation.evaluation
        let key = getStorageKey(user: user, idType: spec.idType)
        let data: [String: Any?] = [
            "value": evaluation.boolValue,
            "rule_id": evaluation.ruleID,
            "json_value": evaluation.jsonValue?.serializeToDictionary(),
            "secondary_exposures": evaluation.secondaryExposures,
            "is_experiment_group": evaluation.isExperimentGroup,
            "group_name": evaluation.groupName,
            "time": detailedEvaluation.details.lcut,
        ]

        guard let json = data.toJsonString() else {
            return
        }

        save(key, spec.name, json)
    }
}
