import Foundation

struct InitializeResponse: Decodable {
    let featureGates: [String: EvaluatedSpec]
    let dynamicConfigs: [String: EvaluatedSpec]
    let layerConfigs: [String: EvaluatedSpec]
    let time: Int
    let hasUpdates: Bool

    enum CodingKeys: String, CodingKey {
        case featureGates = "feature_gates"
        case dynamicConfigs = "dynamic_configs"
        case layerConfigs = "layer_configs"
        case time
        case hasUpdates = "has_updates"
    }
}

struct EvaluatedSpec: Decodable {
    let name: String
    let value: JsonValue
    let ruleID: String?
    let groupName: String?
    let idType: String?
    let secondaryExposures: [ExposureMetadata]?
    let undelegatedSecondaryExposures: [ExposureMetadata]?
    let isDeviceBased: Bool?
    let isExperimentActive: Bool?
    let explicitParameters: [String]?
    let allocatedExperimentName: String?

    enum CodingKeys: String, CodingKey {
        case name
        case value
        case ruleID = "rule_id"
        case groupName = "group_name"
        case idType = "id_type"
        case secondaryExposures = "secondary_exposures"
        case undelegatedSecondaryExposures = "undelegated_secondary_exposures"
        case isDeviceBased = "is_device_based"
        case isExperimentActive = "is_experiment_active"
        case explicitParameters = "explicit_parameters"
        case allocatedExperimentName = "allocated_experiment_name"
    }
}

struct ExposureMetadata: Decodable {
    let gate: String
    let gateValue: String
    let ruleID: String
}
