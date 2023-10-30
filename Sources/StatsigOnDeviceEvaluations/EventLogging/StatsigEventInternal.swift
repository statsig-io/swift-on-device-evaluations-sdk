import Foundation

internal struct StatsigEventInternal {
    let event: StatsigEvent
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
    ])

    return StatsigEvent(
        eventName: GATE_EXPOSURE_NAME,
        metadata: metadata
    )
    .toInternal(user, evaluation.secondaryExposures)
}

internal func createConfigExposure(
    user: StatsigUserInternal,
    configName: String,
    evaluation: EvaluationResult,
    details: EvaluationDetails
) -> StatsigEventInternal {
    let metadata = createExposureMetadata(evaluation, details, [
        "config": configName
    ])

    return StatsigEvent(
        eventName: CONFIG_EXPOSURE_NAME,
        metadata: metadata
    )
    .toInternal(user, evaluation.secondaryExposures)
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
    .toInternal(user, exposures)
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

    return result
}

private extension StatsigEvent {
    func toInternal(
        _ user: StatsigUserInternal,
        _ secondaryExposures: SecondaryExposures?
    ) -> StatsigEventInternal {
        StatsigEventInternal(
            event: self,
            user: user,
            time: Int64(Date().timeIntervalSince1970 * 1000),
            secondaryExposures: secondaryExposures ?? []
        )
    }
}

private let GATE_EXPOSURE_NAME = "statsig::gate_exposure"
private let CONFIG_EXPOSURE_NAME = "statsig::config_exposure"
private let LAYER_EXPOSURE_NAME = "statsig::layer_exposure"
