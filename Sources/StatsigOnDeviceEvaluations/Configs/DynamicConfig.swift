import Foundation

@objc
public class DynamicConfig: ConfigBase {
    @objc public let value: [String: Any]
    @objc public let groupName: String?
    
    let rawValue: Data?

    internal init(
        name: String,
        ruleID: String,
        evaluationDetails: EvaluationDetails,
        value: [String: Any]?,
        rawValue: Data?,
        groupName: String?
    ) {
        self.value = value ?? [:]
        self.groupName = groupName
        self.rawValue = rawValue
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
            rawValue: nil,
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
            rawValue: nil,
            groupName: nil
        )
    }
}
