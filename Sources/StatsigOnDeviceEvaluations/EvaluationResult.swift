import Foundation

struct EvaluationResult {
    let ruleID: String
    let boolValue: Bool
    let jsonValue: JsonValue?
    let unsupported: Bool
    let secondaryExposures: [[String: String]]?
    let undelegatedSecondaryExposures: [[String: String]]?
    let isExperimentGroup: Bool
    let groupName: String?
    let explicitParameters: [String]?
    let configDelegate: String?

    private init(
        ruleID: String? = nil,
        boolValue: Bool = false,
        jsonValue: JsonValue? = nil,
        unsupported: Bool = false,
        secondaryExposures: [[String: String]]? = nil,
        undelegatedSecondaryExposures: [[String: String]]? = nil,
        isExperimentGroup: Bool = false,
        groupName: String? = nil,
        explicitParameters: [String]? = nil,
        configDelegate: String? = nil
    ) {
        self.ruleID = ruleID ?? ""
        self.boolValue = boolValue
        self.jsonValue = jsonValue
        self.unsupported = unsupported
        self.secondaryExposures = secondaryExposures
        self.undelegatedSecondaryExposures = undelegatedSecondaryExposures
        self.isExperimentGroup = isExperimentGroup
        self.groupName = groupName
        self.explicitParameters = explicitParameters
        self.configDelegate = configDelegate
    }

    static func empty() -> EvaluationResult {
        EvaluationResult()
    }

    static func specDefaultResult(
        jsonValue: JsonValue?,
        secondaryExposures: [[String: String]]
    ) -> EvaluationResult {
        EvaluationResult(
            ruleID: "default",
            jsonValue: jsonValue,
            secondaryExposures: secondaryExposures,
            undelegatedSecondaryExposures: secondaryExposures
        )
    }

    static func specResult(
        ruleID: String,
        boolValue: Bool,
        jsonValue: JsonValue?,
        secondaryExposures: [[String: String]],
        isExperimentGroup: Bool
    ) -> EvaluationResult {
        EvaluationResult(
            ruleID: ruleID,
            boolValue: boolValue,
            jsonValue: jsonValue,
            secondaryExposures: secondaryExposures,
            undelegatedSecondaryExposures: secondaryExposures,
            isExperimentGroup: isExperimentGroup
        )
    }

    static func ruleResult(
        ruleID: String,
        boolValue: Bool,
        jsonValue: JsonValue?,
        secondaryExposures: [[String: String]],
        isExperimentGroup: Bool,
        groupName: String?
    ) -> EvaluationResult {
        EvaluationResult(
            ruleID: ruleID,
            boolValue: boolValue,
            jsonValue: jsonValue,
            secondaryExposures: secondaryExposures,
            undelegatedSecondaryExposures: secondaryExposures,
            isExperimentGroup: isExperimentGroup
        )
    }

    static func delegated(
        base: EvaluationResult,
        delegate: String,
        explicitParameters: [String]?,
        secondaryExposures: [[String: String]],
        undelegatedSecondaryExposures: [[String: String]]
    ) -> EvaluationResult {
        EvaluationResult(
            ruleID: base.ruleID,
            boolValue: base.boolValue,
            jsonValue: base.jsonValue,
            unsupported: base.unsupported,
            secondaryExposures: secondaryExposures,
            undelegatedSecondaryExposures: undelegatedSecondaryExposures,
            isExperimentGroup: base.isExperimentGroup,
            groupName: base.groupName,
            explicitParameters: explicitParameters,
            configDelegate: delegate
        )
    }

    static func boolean(
        _ boolValue: Bool,
        _ secondaryExposures: [[String: String]]? = nil
    ) -> EvaluationResult  {
        EvaluationResult(
            boolValue: boolValue,
            secondaryExposures: secondaryExposures
        )
    }

    static func disabled(_ jsonValue: JsonValue?) -> EvaluationResult {
        EvaluationResult(
            ruleID: "disabled",
            jsonValue: jsonValue
        )
    }

    static func unsupported(_ reason: String) -> EvaluationResult {
        return EvaluationResult(
            ruleID: "default",
            unsupported: true
        )
    }
}

