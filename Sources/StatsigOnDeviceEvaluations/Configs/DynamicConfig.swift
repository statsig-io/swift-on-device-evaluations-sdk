import Foundation

@objc
public class DynamicConfig: ConfigBase {
    @objc public let value: [String: Any]
    @objc public let groupName: String?

    internal init(
        name: String,
        ruleID: String,
        evaluationDetails: EvaluationDetails,
        value: [String: Any]?,
        groupName: String?
    ) {
        self.value = value ?? [:]
        self.groupName = groupName
        super.init(
            name,
            ruleID,
            evaluationDetails
        )
    }

    internal static func empty(
        _ name: String,
        _ evalDetails: EvaluationDetails
    ) -> DynamicConfig {
        DynamicConfig(
            name: name,
            ruleID: "",
            evaluationDetails: evalDetails,
            value: nil,
            groupName: nil
        )
    }
    
    @objc(createWithName:andValue:)
    public static func create(
        _ name: String,
        _ value: [String: Any]?
    ) -> DynamicConfig {
        DynamicConfig(
            name: name,
            ruleID: "",
            evaluationDetails: EvaluationDetails.empty(),
            value: value,
            groupName: nil
        )
    }
}
