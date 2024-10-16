import Foundation

typealias ParameterExposureFunc = (_ layer: Layer, _ parameter: String) -> Void

@objc
public class Layer: ConfigBase {
    @objc public let value: [String: Any]
    @objc public let allocatedExperimentName: String?
    @objc public let groupName: String?
    
    let logParameterExposure: ParameterExposureFunc?
    let rawValue: Data?

    internal init(
        name: String,
        ruleID: String,
        evaluationDetails: EvaluationDetails,
        logParameterExposure: ParameterExposureFunc?,
        value: [String: Any]?,
        rawValue: Data?,
        allocatedExperimentName: String? = nil,
        groupName: String? = nil
    ) {
        self.value = value ?? [:]
        self.logParameterExposure = logParameterExposure
        self.allocatedExperimentName = allocatedExperimentName
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
    ) -> Layer {
        Layer(
            name: name,
            ruleID: "",
            evaluationDetails: evalDetails,
            logParameterExposure: nil,
            value: nil,
            rawValue: nil
        )
    }
    
    @objc(createWithName:andValue:)
    public static func create(
        _ name: String,
        _ value: [String: Any]?
    ) -> Layer {
        Layer(
            name: name,
            ruleID: "",
            evaluationDetails: EvaluationDetails.empty(),
            logParameterExposure: nil,
            value: value,
            rawValue: nil
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
