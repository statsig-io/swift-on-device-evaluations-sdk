import Foundation

@objc
public class EvaluationDetails: NSObject {
    @objc public let reason: String
    @objc public let time: Int64

    static func unrecognized() -> EvaluationDetails {
        EvaluationDetails(
            reason: "Unrecognized",
            time: Time.now()
        )
    }

    internal init(reason: String, time: Int64) {
        self.reason = reason
        self.time = time
    }
}
