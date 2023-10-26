import Foundation

typealias DetailedEvaluatedSpec = (
    evaluation: EvaluatedSpec?,
    details: EvaluationDetails
)

class EvaluationStore {
    enum ConfigType {
        case gate
        case config
        case layer
    }

    private var values: InitializeResponse?

    func getEvaluation(_ type: ConfigType, name: String) -> DetailedEvaluatedSpec {
        let result = self.values?.featureGates[name]
        return (result, EvaluationDetails(reason: "", time: 0))
    }

    func setValues(_ values: InitializeResponse, source: ValueSource) {
        self.values = values
    }
}
