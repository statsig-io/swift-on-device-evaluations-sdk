import Foundation

typealias ParameterExposureFunc = (_ layer: Layer, _ parameter: String) -> Void

@objc
public class Layer: ConfigBase {
    @objc public let value: [String: Any]
    let logParameterExposure: ParameterExposureFunc?
    @objc public let allocatedExperimentName: String?
    @objc public let groupName: String?

    internal init(
        name: String,
        ruleID: String,
        evaluationDetails: EvaluationDetails,
        logParameterExposure: ParameterExposureFunc?,
        value: [String: Any]?,
        allocatedExperimentName: String? = nil,
        groupName: String? = nil
    ) {
        self.value = value ?? [:]
        self.logParameterExposure = logParameterExposure
        self.allocatedExperimentName = allocatedExperimentName
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
