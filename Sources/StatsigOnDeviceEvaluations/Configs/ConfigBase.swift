import Foundation

public class ConfigBase: NSObject {
    @objc public let name: String
    @objc public let ruleID: String
    @objc public let evaluationDetails: EvaluationDetails

    internal init(_ name: String, _ ruleID: String, _ evaluationDetails: EvaluationDetails) {
        self.name = name
        self.ruleID = ruleID
        self.evaluationDetails = evaluationDetails
    }
}
