import Foundation
import CommonCrypto

typealias DetailedEvaluation = (
    evaluation: EvaluationResult,
    details: EvaluationDetails
)

class Evaluator {
    private let store: SpecStore

    init(_ store: SpecStore) {
        self.store = store
    }

    public func checkGate(_ name: String, _ user: StatsigUser) -> DetailedEvaluation {
        evaluateWithDetails(
            store.getSpecAndSrouceInfo(.gate, name),
            user
        )
    }

    public func getConfig(_ name: String, _ user: StatsigUser) -> DetailedEvaluation {
        evaluateWithDetails(
            store.getSpecAndSrouceInfo(.config, name),
            user
        )
    }

    public func getLayer(_ name: String, _ user: StatsigUser) -> DetailedEvaluation {
        evaluateWithDetails(
            store.getSpecAndSrouceInfo(.layer, name),
            user
        )
    }
}

// MARK: Private
extension Evaluator {
    private func evaluateWithDetails(
        _ specAndSourceInfo: (spec: Spec?, sourceInfo: SpecStoreSourceInfo),
        _ user: StatsigUser)
    -> DetailedEvaluation {
        let (spec, info) = specAndSourceInfo
        guard let spec = spec else {
            return (
                evaluation: .empty(),
                details: .unrecognized()
            )
        }

        return (
            evaluation: evaluateSpec(spec, user),
            details: EvaluationDetails(
                reason: info.source.rawValue,
                time: info.receivedAt
            )
        )
    }

    private func evaluateSpec(_ spec: Spec, _ user: StatsigUser) -> EvaluationResult {
        guard spec.enabled else {
            return .disabled(spec.defaultValue)
        }

        var exposures = [[String: String]]()

        for rule in spec.rules {
            let result = evaluateRule(rule, user)

            if result.unsupported {
                return result
            }

            if let resultExposures = result.secondaryExposures {
                exposures.append(contentsOf: resultExposures)
            }

            if !result.boolValue {
                continue
            }

            if let delegatedResult = evaluateDelegate(rule, user, exposures) {
                return delegatedResult
            }

            let pass = evaluatePassPercentage(rule, spec.salt, user)
            return .specResult(
                ruleID: result.ruleID,
                boolValue: pass,
                jsonValue: pass ? result.jsonValue : spec.defaultValue,
                secondaryExposures: exposures,
                isExperimentGroup: result.isExperimentGroup
            )
        }

        return .specDefaultResult(
            jsonValue: spec.defaultValue,
            secondaryExposures: exposures
        )
    }

    private func evaluateRule(_ rule: SpecRule, _ user: StatsigUser) -> EvaluationResult {
        var exposures = [[String: String]]()
        var pass = true

        for condition in rule.conditions {
            let result = evaluateCondition(condition, user)

            if result.unsupported {
                return result
            }

            if let resultExposures = result.secondaryExposures {
                exposures.append(contentsOf: resultExposures)
            }

            if !result.boolValue {
                pass = false
            }
        }

        return .ruleResult(
            ruleID: rule.id,
            boolValue: pass,
            jsonValue: rule.returnValue,
            secondaryExposures: exposures,
            isExperimentGroup: rule.isExperimentGroup ?? false,
            groupName: rule.groupName
        )
    }

    private func evaluateDelegate(
        _ rule: SpecRule,
        _ user: StatsigUser,
        _ exposures: [[String: String]]
    ) -> EvaluationResult? {
        guard let delegate = rule.configDelegate else {
            return nil
        }

        let specAndInfo = store.getSpecAndSrouceInfo(.config, delegate)
        guard let spec = specAndInfo.spec else {
            return nil
        }

        let result = evaluateSpec(spec, user)
        return .delegated(
            base: result,
            delegate: delegate,
            explicitParameters: spec.explicitParameters,
            secondaryExposures: exposures + (result.secondaryExposures ?? []),
            undelegatedSecondaryExposures: exposures
        )
    }

    private func evaluateCondition(_ condition: SpecCondition, _ user: StatsigUser) -> EvaluationResult {
        var value: JsonValue? = nil
        var pass = false

        let field = condition.field
        let target = condition.targetValue
        let idType = condition.idType
        let type = condition.type.lowercased()

        switch (type) {
        case "public":
            return .boolean(true)

        case "pass_gate", "fail_gate":
            let result = evaluateNestedGate(
                target?.asString() ?? "",
                user
            )

            return .boolean(
                type == "fail_gate" ? !result.boolValue : result.boolValue,
                result.secondaryExposures
            )

        case "multi_pass_gate", "multi_fail_gate":
            guard let gates = target?.asJsonArray() else {
                return .unsupported(type)
            }

            return evaluateNestedGates(gates, type, user)

        case "user_field":
            value = user.getUserValue(field)
            break

        case "environment_field":
            value = user.getFromEnvironment(field)
            break

        case "current_time":
            value = .int(Time.now())
            break

        case "user_bucket":
            let hash = getHashForUserBucket(condition, user) % 1000
            value = .int(Int64(hash))
            break

        case "unit_id":
            if let unitID = user.getUnitID(idType) {
                value = .string(unitID)
            }
            break

        case "ip_based", "ua_based":
            return .unsupported(type)

        default:
            return .unsupported(condition.type.lowercased())
        }

        let op = condition.operator?.lowercased()
        switch (op) {

        case "gt", "gte", "lt", "lte":
            pass = Comparison.numbers(value, target, op)

        case "version_gt", "version_gte",
            "version_lt", "version_lte",
            "version_eq", "version_neq":
            pass = Comparison.versions(value, target, op)

        case "any", "none",
            "str_starts_with_any", "str_ends_with_any",
            "str_contains_any", "str_contains_none":
            pass = Comparison.stringInArray(value, target, op, ignoreCase: true)

        case "any_case_sensitive", "none_case_sensitive":
            pass = Comparison.stringInArray(value, target, op, ignoreCase: false)

        case "str_matches":
            pass = Comparison.stringWithRegex(value, target)

        case "before", "after", "on":
            pass = Comparison.time(value, target, op)

        case "eq":
            pass = value == target

        case "neq":
            pass = value != target

        case "in_segment_list":
            return .unsupported("in_segment_list")
        case "not_in_segment_list":
            return .unsupported("not_in_segment_list")

        default:
            return .unsupported("Operator Was Null")
        }

        return .boolean(pass)
    }


    private func evaluateNestedGates(
        _ gateNames: [JsonValue],
        _ type: String,
        _ user: StatsigUser
    ) -> EvaluationResult {
        let isMultiPassGateType = type == "multi_pass_gate"
        var exposures = [[String: String]]()
        var pass = false

        for name in gateNames {
            guard let name = name.asString() else {
                return .unsupported("Expected gate name to be string.")
            }

            let result = evaluateNestedGate(name, user)
            if result.unsupported {
                return result
            }

            if let resultExposures = result.secondaryExposures {
                exposures.append(contentsOf: resultExposures)
            }

            if (isMultiPassGateType == result.boolValue) {
                pass = true
                break
            }
        }

        return .boolean(
            pass,
            exposures
        )
    }

    private func evaluateNestedGate(
        _ gateName: String,
        _ user: StatsigUser
    ) -> EvaluationResult {
        var exposures = [[String: String]]()
        var passing = false

        if let gateSpec = store.getSpecAndSrouceInfo(.gate, gateName).spec {
            let gateResult = evaluateSpec(gateSpec, user)
            if gateResult.unsupported {
                return gateResult
            }

            passing = gateResult.boolValue
            exposures.append(contentsOf: gateResult.secondaryExposures ?? [])
            exposures.append(createGateExposureData(
                gateName, passing, gateResult.ruleID
            ))
        }

        return .boolean(
            passing,
            exposures
        )
    }

    private func evaluatePassPercentage(
        _ rule: SpecRule,
        _ specSalt: String,
        _ user: StatsigUser
    ) -> Bool {
        let unitID = user.getUnitID(rule.idType) ?? ""
        let hash = computeUserHash("\(specSalt).\(rule.salt).\(unitID)")
        return (hash % 10_000) < (rule.passPercentage * 100)
    }

    private func getHashForUserBucket(_ condition: SpecCondition, _ user: StatsigUser) -> UInt64 {
        let unitID = user.getUnitID(condition.idType) ?? ""
        let salt = condition.additionalValues?["salt"]?.asString() ?? ""
        let hash = computeUserHash("\(salt).\(unitID)")
        return hash % 1000
    }

    private func computeUserHash(_ value: String) -> UInt64 {
        let data = value.utf8
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        _ = data.withContiguousStorageIfAvailable { buffer in
            if let baseAddress = buffer.baseAddress {
                _ = CC_SHA256(baseAddress, CC_LONG(data.count), &digest)
            }
        }

        let uint64Value = digest.prefix(MemoryLayout<UInt64>.size).reduce(UInt64(0)) {
            $0 << 8 | UInt64($1)
        }

        return uint64Value
//        let data = Data(value.utf8)
//        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
//
//        data.withUnsafeBytes {
//            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
//        }
//
//        let uint64Array = Array(digest.prefix(MemoryLayout<UInt64>.size))
//        let uint64Value = uint64Array.withUnsafeBytes {
//            $0.load(as: UInt64.self)
//        }
//
//        return UInt64(bigEndian: uint64Value)
    }
}

extension Double {
    func startOfDay() -> Double {
        let calendar = Calendar.current
        let date = Date(timeIntervalSince1970: self)
        let startOfDay = calendar.startOfDay(for: date)
        return startOfDay.timeIntervalSince1970
    }
}
