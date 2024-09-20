import Foundation

@objc
public class FeatureGate: ConfigBase {
    @objc public let value: Bool

    internal init(
        name: String,
        ruleID: String,
        evaluationDetails: EvaluationDetails,
        value: Bool
    ) {
        self.value = value
        super.init(name, ruleID, evaluationDetails)
    }

    internal static func empty(
        _ name: String,
        _ evalDetails: EvaluationDetails
    ) -> FeatureGate {
        return FeatureGate(
            name: name,
            ruleID: "",
            evaluationDetails: evalDetails,
            value: false
        )
    }
    
    @objc(createWithName:andValue:)
    public static func create(
        _ name: String,
        _ value: Bool
    ) -> FeatureGate {
        FeatureGate(
            name: name,
            ruleID: "",
            evaluationDetails: EvaluationDetails.empty(),
            value: value
        )
    }
}
