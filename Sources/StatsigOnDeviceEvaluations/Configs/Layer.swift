import Foundation

typealias ParameterExposureFunc = (_ layer: Layer, _ parameter: String) -> Void

@objc
public class Layer: ConfigBase {
    let value: [String: Any]
    let logParameterExposure: ParameterExposureFunc?

    internal init(
        name: String,
        ruleID: String,
        evaluationDetails: EvaluationDetails,
        logParameterExposure: ParameterExposureFunc?,
        value: [String: Any]?
    ) {
        self.value = value ?? [:]
        self.logParameterExposure = logParameterExposure

        super.init(
            name,
            ruleID,
            evaluationDetails
        )
    }

    internal static func empty(
        _ name: String,
        _ evalDetails: EvaluationDetails
    ) -> Layer {
        Layer(
            name: name,
            ruleID: "",
            evaluationDetails: evalDetails,
            logParameterExposure: nil,
            value: nil
        )
    }

    @objc
    public func getValue(param: String, fallback: Any) -> Any {
        guard let result = value[param] else {
            return fallback
        }

        self.logParameterExposure?(self, param)

        return result
    }
}
