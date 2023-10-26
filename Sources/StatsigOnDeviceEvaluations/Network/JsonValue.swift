import Foundation

public enum JsonValue: Decodable, Equatable {
    case string(String)
    case int(Int64)
    case double(Double)
    case bool(Bool)
    case dictionary([String: JsonValue])
    case array([JsonValue])
    case null

    public init?(_ value: Any?) {
        if let value = value as? [String] {
            self = .array(value.map{ .string($0) })
        }

        else if let value = value as? String {
            self = .string(value)
        }

        else if let value = value as? Double {
            self = .double(value)
        }

        else if let value = value as? Int {
            self = .int(Int64(value))
        }

        else if let value = value as? Bool {
            self = .bool(value)
        }

        return nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        }

        else if let intVal = try? container.decode(Int.self) {
            self = .int(Int64(intVal))
        }

        else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        }

        else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        }

        else if let dictValue = try? container.decode([String: JsonValue].self) {
            self = .dictionary(dictValue)
        }

        else if let arrValue = try? container.decode([JsonValue].self) {
            self = .array(arrValue)
        }

        else {
            throw DecodingError.typeMismatch(
                JsonValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid type for targetValue"
                )
            )
        }
    }
}

extension JsonValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

}


// MARK: Out Conversion
extension JsonValue {
    public func serializeToDictionary() -> [String: Any]? {
        guard case .dictionary(let dictionary) = self else {
            return nil
        }

        do {
            let encoder = JSONEncoder()
            let data = try! encoder.encode(dictionary)
            return try JSONSerialization.jsonObject(
                with: data,
                options: []
            ) as? [String: Any]
        } catch {
            return nil
        }
    }

    public func asJsonArray() -> [JsonValue]? {
        guard case .array(let array) = self else {
            return nil
        }
        return array
    }

    public func asString() -> String? {
        switch self {
        case .int(let value):
            return String(value)

        case .double(let value):
            return String(value)

        case .bool(let value):
            return String(value)

        case .string(let value):
            return value

        default:
            return nil
        }
    }

    public func asDouble() -> Double? {
        switch self {
        case .int(let value):
            return Double(value)
        case .double(let value):
            return value
        default:
            return nil
        }
    }

    public func asBool() -> Bool? {
        switch self {
        case .bool(let value):
            return value
        default:
            return nil
        }
    }
}
