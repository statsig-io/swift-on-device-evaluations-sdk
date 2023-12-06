import Foundation

@objc
public class Experiment: DynamicConfig {
    internal static func emptyExperiment(
        _ name: String,
        _ evalDetails: EvaluationDetails
    ) -> Experiment {
        Experiment(
            name: name,
            ruleID: "",
            evaluationDetails: evalDetails,
            value: nil
        )
    }
}
