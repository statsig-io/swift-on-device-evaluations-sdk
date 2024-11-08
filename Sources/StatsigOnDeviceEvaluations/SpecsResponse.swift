import Foundation


enum SpecsResponse: Decodable {
    case full(SpecsResponseFull)
    case noUpdates

    private enum CodingKeys: String, CodingKey {
        case hasUpdates = "has_updates"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hasUpdates = try container.decode(Bool.self, forKey: .hasUpdates)

        if hasUpdates {
            let full = try SpecsResponseFull(from: decoder)
            self = .full(full)
        } else {
            self = .noUpdates
        }
    }
}

struct SpecsResponseFull: Decodable {
    let featureGates: [Spec]
    let dynamicConfigs: [Spec]
    let layerConfigs: [Spec]
    let time: Int64

    private enum CodingKeys: String, CodingKey {
        case featureGates = "feature_gates"
        case dynamicConfigs = "dynamic_configs"
        case layerConfigs = "layer_configs"
        case time
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
    let version: Int32?
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


@objc
public protocol SynchronousSpecsValue {}

extension NSData: SynchronousSpecsValue {}
extension NSString: SynchronousSpecsValue {}

struct ParsedDownloadConfigSpecsResponse {
    let response: SpecsResponseFull
    let raw: Data
}

func parseSpecsValue(_ value: SynchronousSpecsValue) -> (ParsedDownloadConfigSpecsResponse?, Error?) {
    var data: Data?

    if let value = value as? Data {
        data = value
    }
    else if let value = value as? String {
        data = Data(value.utf8)
    }

    guard let data = data else {
        return (nil, StatsigError.failedToParseSpecsValue)
    }

    do {
        let decoded = try JSONDecoder()
            .decode(SpecsResponseFull.self, from: data)

        return (ParsedDownloadConfigSpecsResponse(response: decoded, raw: data), nil)
    } catch {
        return (nil, error)
    }
}
