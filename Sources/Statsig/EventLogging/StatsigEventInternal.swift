import Foundation

internal struct StatsigEventInternal {
    let event: StatsigEvent
    let user: StatsigUser
    let time: Int64
    let secondaryExposures: [String]?
}

internal func createGateExposure(
    user: StatsigUser,
    gateName: String,
    gateValue: Bool,
    ruleID: String,
    secondaryExposures: [String]
) -> StatsigEventInternal {
    StatsigEvent(
        eventName: GATE_EXPOSURE_NAME,
        metadata: createGateExposureData(
            gateName, gateValue, ruleID
        )
    )
    .toInternal(user, secondaryExposures)
}

internal func createConfigExposure(
    user: StatsigUser,
    gateName: String,
    gateValue: Bool,
    ruleID: String,
    secondaryExposures: [String]
) -> StatsigEventInternal {
    StatsigEvent(
        eventName: CONFIG_EXPOSURE_NAME,
        metadata: [
            "gate": gateName,
            "gateValue": String(gateValue),
            "ruleID": ruleID
        ])
    .toInternal(user, secondaryExposures)
}

internal func createLayerExposure(
    user: StatsigUser,
    gateName: String,
    gateValue: Bool,
    ruleID: String,
    secondaryExposures: [String]
) -> StatsigEventInternal {
    StatsigEvent(
        eventName: LAYER_EXPOSURE_NAME,
        metadata:

            [
            "gate": gateName,
            "gateValue": String(gateValue),
            "ruleID": ruleID
        ])
    .toInternal(user, secondaryExposures)
}

internal func createGateExposureData(
    _ gate: String,
    _ value: Bool,
    _ ruleID: String
) -> [String: String] {
    return [
        "gate": gate,
        "gateValue": String(value),
        "ruleID": ruleID
    ]
}

private extension StatsigEvent {
    func toInternal(_ user: StatsigUser, _ secondaryExposures: [String]) -> StatsigEventInternal {
        StatsigEventInternal(
            event: self,
            user: user,
            time: Int64(Date().timeIntervalSince1970 * 1000),
            secondaryExposures: secondaryExposures
        )
    }
}

private let GATE_EXPOSURE_NAME = "statsig::gate_exposure"
private let CONFIG_EXPOSURE_NAME = "statsig::config_exposure"
private let LAYER_EXPOSURE_NAME = "statsig::layer_exposure"
