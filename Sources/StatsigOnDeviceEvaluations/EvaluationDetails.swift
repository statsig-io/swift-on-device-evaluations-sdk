import Foundation

@objc
public class EvaluationDetails: NSObject {
    @objc public let reason: String
    @objc public let systemTime: Int64
    @objc public let receivedAt: Int64
    @objc public let lcut: Int64

    static func userError(_ storeInfo: SpecStoreSourceInfo) -> EvaluationDetails {
        EvaluationDetails(
            reason: "UserError",
            lcut: storeInfo.lcut,
            receivedAt: storeInfo.receivedAt
        )
    }

    static func unrecognized(_ storeInfo: SpecStoreSourceInfo) -> EvaluationDetails {
        EvaluationDetails(
            reason: "Unrecognized",
            lcut: storeInfo.lcut,
            receivedAt: storeInfo.receivedAt
        )
    }

    static func uninitialized() -> EvaluationDetails {
        EvaluationDetails(
            reason: "Uninitialized",
            lcut: 0,
            receivedAt: 0
        )
    }

    static func sticky(_ lcut: Int64) -> EvaluationDetails {
        EvaluationDetails(
            reason: "Persisted",
            lcut: 0,
            receivedAt: Time.now()
        )
    }

    internal init(reason: String, lcut: Int64, receivedAt: Int64) {
        self.reason = reason
        self.lcut = lcut
        self.receivedAt = receivedAt
        self.systemTime = Time.now()
    }

    internal init(sourceInfo: SpecStoreSourceInfo) {
        self.reason = sourceInfo.source.rawValue
        self.lcut = sourceInfo.lcut
        self.receivedAt = sourceInfo.receivedAt
        self.systemTime = Time.now()
    }
}
