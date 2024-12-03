import Foundation

internal struct StatsigEventInternal {
    let eventName: String
    let value: StatsigEventValue?
    let metadata: [String: Any]?
    let user: StatsigUserInternal
    let time: Int64
    let secondaryExposures: SecondaryExposures?
}

typealias SecondaryExposures = [[String: String]]

internal func createGateExposure(
    user: StatsigUserInternal,
    gateName: String,
    evaluation: EvaluationResult,
    details: EvaluationDetails
) -> StatsigEventInternal {
    let metadata = createExposureMetadata(evaluation, details, [
        "gate": gateName,
        "gateValue": "\(evaluation.boolValue)"
    ])

    return StatsigEvent(
        eventName: GATE_EXPOSURE_NAME,
        metadata: metadata
    )
    .toInternalWithExposures(user, evaluation.secondaryExposures)
}

internal func createConfigExposure(
    user: StatsigUserInternal,
    configName: String,
    evaluation: EvaluationResult,
    details: EvaluationDetails
) -> StatsigEventInternal {
    let metadata = createExposureMetadata(evaluation, details, [
        "config": configName,
        "rulePassed": "\(evaluation.boolValue)"
    ])

    return StatsigEvent(
        eventName: CONFIG_EXPOSURE_NAME,
        metadata: metadata
    )
    .toInternalWithExposures(user, evaluation.secondaryExposures)
}

internal func createLayerExposure(
    user: StatsigUserInternal,
    layerName: String,
    parameter: String,
    evaluation: EvaluationResult,
    details: EvaluationDetails
) -> StatsigEventInternal {
    var allocatedExperiment = ""
    var exposures = evaluation.undelegatedSecondaryExposures
    let isExplicit = evaluation.explicitParameters?.contains(parameter) ?? false
    if isExplicit {
        exposures = evaluation.secondaryExposures
        allocatedExperiment = evaluation.configDelegate ?? ""
    }

    let metadata = createExposureMetadata(evaluation, details, [
        "config": layerName,
        "allocatedExperiment": allocatedExperiment,
        "parameterName": parameter,
        "isExplicitParameter": "\(isExplicit)",
    ])

    return StatsigEvent(
        eventName: LAYER_EXPOSURE_NAME,
        metadata:metadata
    )
    .toInternalWithExposures(user, exposures)
}

internal func createExposureMetadata(
    _ evaluation: EvaluationResult,
    _ details: EvaluationDetails,
    _ extra: [String: String]
) -> [String: String] {
    let lcut = String(details.lcut)

    var result = [
        "ruleID": evaluation.ruleID,
        "reason": details.reason,
        "configSyncTime": lcut,
        "initTime": lcut,
        "serverTime": String(details.systemTime)
    ]

    for (key, value) in extra {
        result[key] = value
    }
    
    if let version = evaluation.version {
        result["configVersion"] = String(version)
    }

    return result
}

extension StatsigEvent {
    func toInternalWithExposures(
        _ user: StatsigUserInternal,
        _ secondaryExposures: SecondaryExposures?
    )  -> StatsigEventInternal {
        toInternal(user, secondaryExposures ?? [])
    }

    func toInternal(
        _ user: StatsigUserInternal,
        _ secondaryExposures: SecondaryExposures? = nil
    ) -> StatsigEventInternal {
        StatsigEventInternal(
            eventName: self.eventName,
            value: self.value,
            metadata: self.metadata,
            user: user,
            time: Time.now(),
            secondaryExposures: secondaryExposures
        )
    }
}

private let GATE_EXPOSURE_NAME = "statsig::gate_exposure"
private let CONFIG_EXPOSURE_NAME = "statsig::config_exposure"
private let LAYER_EXPOSURE_NAME = "statsig::layer_exposure"
