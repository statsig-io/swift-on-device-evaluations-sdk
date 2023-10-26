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
}
