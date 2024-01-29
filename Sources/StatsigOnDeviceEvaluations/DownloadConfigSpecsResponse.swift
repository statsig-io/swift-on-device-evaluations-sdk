import Foundation

struct DownloadConfigSpecsResponse: Decodable {
    let featureGates: [Spec]
    let dynamicConfigs: [Spec]
    let layerConfigs: [Spec]
    let time: Int64
    let hasUpdates: Bool

    enum CodingKeys: String, CodingKey {
        case featureGates = "feature_gates"
        case dynamicConfigs = "dynamic_configs"
        case layerConfigs = "layer_configs"
        case time
        case hasUpdates = "has_updates"
    }
}

struct Spec: Decodable {
    let name: String
    let type: String
    let salt: String
    let defaultValue: JsonValue
    let enabled: Bool
    let idType: String
    let explicitParameters: [String]?
    let rules: [SpecRule]
    let isActive: Bool?
}

struct SpecRule: Decodable {
    let name: String
    let passPercentage: Double
    let conditions: [SpecCondition]
    let returnValue: JsonValue
    let id: String
    let salt: String
    let idType: String
    let configDelegate: String?
    let isExperimentGroup: Bool?
    let groupName: String?
}

struct SpecCondition: Decodable {
    let type: String
    let targetValue: JsonValue?
    let `operator`: String?
    let field: String?
    let additionalValues: [String: JsonValue]?
    let idType: String
}
