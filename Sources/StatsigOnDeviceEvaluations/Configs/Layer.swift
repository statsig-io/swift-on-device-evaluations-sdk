import Foundation

@objc
public class Layer: ConfigBase {
    let value: [String: Any]

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

    @objc
    public func getValue(param: String, fallback: Any) -> Any {
        return value[param] ?? fallback
    }
}
