import Foundation

@objc
public class DynamicConfig: ConfigBase {
    @objc public let value: [String: Any]

    internal init(
        name: String,
        ruleID: String,
        evaluationDetails: EvaluationDetails,
        value: [String: Any]?
    ) {
        self.value = value ?? [:]
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
            value: nil
        )
    }
}
