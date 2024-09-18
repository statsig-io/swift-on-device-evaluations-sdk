import Foundation
import CommonCrypto

typealias DetailedEvaluation = (
    evaluation: EvaluationResult,
    details: EvaluationDetails
)

class Evaluator {
    private let store: SpecStore
    private let emitter: StatsigClientEventEmitter
    private let userPersistentStorageProvider: UserPersistentStorageProvider?
    private let overrideAdapter: OverrideAdapter?


    init(
        _ store: SpecStore,
        _ emitter: StatsigClientEventEmitter,
        _ userPersistentStorageProvider: UserPersistentStorageProvider?,
        _ overrideAdapter: OverrideAdapter?
    ) {
        self.store = store
        self.emitter = emitter
        self.userPersistentStorageProvider = userPersistentStorageProvider
        self.overrideAdapter = overrideAdapter
    }

    public func checkGate(_ name: String, _ user: StatsigUserInternal, _ options: GetFeatureGateOptions?) -> DetailedEvaluation {
        if let gate = overrideAdapter?.getGate(user.user, name, options) {
            return (
                evaluation: .gateOverride(gate),
                details: .localOverride(store.sourceInfo.lcut)
            )
        }
        
        let (spec, info) = store.getSpecAndSourceInfo(.gate, name)
        guard let spec: Spec = spec else {
            return (
                evaluation: .empty(),
                details: .unrecognized(info)
            )
        }

        return evaluateWithDetails(EvaluationArgs(
            unhashedName: name,
            spec: spec,
            sourceInfo: info,
            user: user,
            persistedValues: nil
        ))
    }
    
    public func getConfig(
        _ name: String,
        _ user: StatsigUserInternal,
        _ options: GetDynamicConfigOptions? = nil
    ) -> DetailedEvaluation {
        if let config = overrideAdapter?.getConfig(user.user, name, options) {
            return (
                evaluation: .configOverride(config),
                details: .localOverride(store.sourceInfo.lcut)
            )
        }

        return getConfigImpl(name, user)
    }
    
    public func getExperiment(
        _ name: String,
        _ user: StatsigUserInternal,
        _ options: GetExperimentOptions? = nil
    ) -> DetailedEvaluation {
        if let experiment = overrideAdapter?.getExperiment(user.user, name, options) {
            return (
                evaluation: .experimentOverride(experiment),
                details: .localOverride(store.sourceInfo.lcut)
            )
        }
        
        return getConfigImpl(name, user, options)
    }

    public func getConfigImpl(
        _ name: String,
        _ user: StatsigUserInternal,
        _ options: GetExperimentOptions? = nil
    ) -> DetailedEvaluation {
        let (spec, info) = store.getSpecAndSourceInfo(.config, name)
        guard let spec: Spec = spec else {
            return (
                evaluation: .empty(),
                details: .unrecognized(info)
            )
        }
        
        let persistedValues = options?.userPersistedValues

        return evaluateConfigWithPersistedValues(EvaluationArgs(
            unhashedName: name,
            spec: spec,
            sourceInfo: info,
            user: user,
            persistedValues: persistedValues
        ))
    }

    public func getLayer(
        _ name: String,
        _ user: StatsigUserInternal,
        options: GetLayerOptions?
    ) -> DetailedEvaluation {
        if let layer = overrideAdapter?.getLayer(user.user, name, options) {
            return (
                evaluation: .layerOverride(layer),
                details: .localOverride(store.sourceInfo.lcut)
            )
        }

        let (spec, info) = store.getSpecAndSourceInfo(.layer, name)
        guard let spec: Spec = spec else {
            return (
                evaluation: .empty(),
                details: .unrecognized(info)
            )
        }

        return evaluateLayerWithPersistedValues(EvaluationArgs(
            unhashedName: name,
            spec: spec,
            sourceInfo: info,
            user: user,
            persistedValues: options?.userPersistedValues
        ))
    }
}

struct EvaluationArgs {
    let unhashedName: String;
    let spec: Spec;
    let sourceInfo: SpecStoreSourceInfo;
    let user: StatsigUserInternal;
    let persistedValues: UserPersistedValues?;
}

// MARK: Private
extension Evaluator {
    private func evaluateConfigWithPersistedValues(_ args: EvaluationArgs) -> DetailedEvaluation {
        guard
            let persistedValues: UserPersistedValues = args.persistedValues,
            args.spec.isActive == true
        else {
            return evaluateAndDeleteFromPersistentStorage(args)
        }

        guard
            let stickyEval: DetailedEvaluation = userPersistentStorageProvider?.getStickyValue(args.user, args.spec, persistedValues)
        else {
            return evaluateAndSaveToPersistentStorage(args)
        }

        return stickyEval
    }

    private func evaluateLayerWithPersistedValues(_ args: EvaluationArgs) -> DetailedEvaluation {
        guard let persistedValues: UserPersistedValues = args.persistedValues else {
            return evaluateAndDeleteFromPersistentStorage(args)
        }

        guard
            let stickyEvaluation: DetailedEvaluation = userPersistentStorageProvider?.getStickyValue(args.user, args.spec, persistedValues)
        else {
            let detailedEvaluation: DetailedEvaluation = evaluateWithDetails(args)
            if (allocatedExperimentExistsAndIsActive(detailedEvaluation)) {
                userPersistentStorageProvider?.saveStickyValue(args.user, args.spec, detailedEvaluation)
            } else {
                userPersistentStorageProvider?.deleteStickyValue(args.user, args.spec)
            }
            return detailedEvaluation
        }

        if (allocatedExperimentExistsAndIsActive(stickyEvaluation)) {
            return stickyEvaluation
        } else {
            return evaluateAndDeleteFromPersistentStorage(args)
        }
    }

    private func allocatedExperimentExistsAndIsActive(_ detailedEvaluation: DetailedEvaluation) -> Bool {
        guard 
            let delegateName = detailedEvaluation.evaluation.configDelegate,
            let delegate = store.getSpecAndSourceInfo(.config, delegateName).spec
        else {
            return false
        }
        return delegate.isActive == true
    }

    private func evaluateAndSaveToPersistentStorage(_ args: EvaluationArgs) -> DetailedEvaluation {
        let detailedEvaluation = evaluateWithDetails(args)
        userPersistentStorageProvider?.saveStickyValue(args.user, args.spec, detailedEvaluation)
        return detailedEvaluation
    }

    private func evaluateAndDeleteFromPersistentStorage(_ args: EvaluationArgs) -> DetailedEvaluation {
        userPersistentStorageProvider?.deleteStickyValue(args.user, args.spec)
        return evaluateWithDetails(args)
    }

    private func evaluateWithDetails(_ args: EvaluationArgs) -> DetailedEvaluation {
        return (
            evaluation: evaluateSpec(args.spec, args.user),
            details: EvaluationDetails(sourceInfo: args.sourceInfo)
        )
    }

    private func evaluateSpec(_ spec: Spec, _ user: StatsigUserInternal) -> EvaluationResult {
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
                isExperimentGroup: result.isExperimentGroup,
                groupName: result.groupName
            )
        }

        return .specDefaultResult(
            jsonValue: spec.defaultValue,
            secondaryExposures: exposures
        )
    }

    private func evaluateRule(_ rule: SpecRule, _ user: StatsigUserInternal) -> EvaluationResult {
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
        _ user: StatsigUserInternal,
        _ exposures: [[String: String]]
    ) -> EvaluationResult? {
        guard let delegate = rule.configDelegate else {
            return nil
        }

        let specAndInfo = store.getSpecAndSourceInfo(.config, delegate)
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

    private func evaluateCondition(_ condition: SpecCondition, _ user: StatsigUserInternal) -> EvaluationResult {
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
                return getUnsupportedResult(type)
            }

            return evaluateNestedGates(gates, type, user)

        case "user_field", "ip_based", "ua_based":
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

        default:
            return getUnsupportedResult(condition.type.lowercased())
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
            return getUnsupportedResult("in_segment_list")
        case "not_in_segment_list":
            return getUnsupportedResult("not_in_segment_list")

        default:
            return getUnsupportedResult("Operator Was Null")
        }

        return .boolean(pass)
    }


    private func evaluateNestedGates(
        _ gateNames: [JsonValue],
        _ type: String,
        _ user: StatsigUserInternal
    ) -> EvaluationResult {
        let isMultiPassGateType = type == "multi_pass_gate"
        var exposures = [[String: String]]()
        var pass = false

        for name in gateNames {
            guard let name = name.asString() else {
                return getUnsupportedResult("Expected gate name to be string.")
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
        _ user: StatsigUserInternal
    ) -> EvaluationResult {
        var exposures = [[String: String]]()
        var gateResult: EvaluationResult? = nil
        
        if let gateSpec = store.getSpecAndSourceInfo(.gate, gateName).spec {
            gateResult = evaluateSpec(gateSpec, user)
        }
        
        exposures.append(contentsOf: gateResult?.secondaryExposures ?? [])
        exposures.append([
            "gate": gateName,
            "gateValue": String(gateResult?.boolValue ?? false),
            "ruleID": gateResult?.ruleID ?? ""
        ])
        
        return .boolean(
            gateResult?.boolValue ?? false,
            exposures
        )
    }

    private func evaluatePassPercentage(
        _ rule: SpecRule,
        _ specSalt: String,
        _ user: StatsigUserInternal
    ) -> Bool {
        let unitID = user.getUnitID(rule.idType) ?? ""
        let hash = computeUserHash("\(specSalt).\(rule.salt).\(unitID)")
        return Double(hash % 10_000) < (rule.passPercentage * 100.0)
    }

    private func getHashForUserBucket(_ condition: SpecCondition, _ user: StatsigUserInternal) -> UInt64 {
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
    }


}


// MARK: Unsupported Eval
extension Evaluator {
    func getUnsupportedResult(_ reason: String) -> EvaluationResult {
        emitter.emitError("Unsupported condition or operator: \(reason)")
        return .unsupported(reason)
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
