import Foundation

public protocol TypedGroupName {
    init?(rawValue: String)
}

public struct TypedNoValue: Decodable {}

public protocol TypedExperiment {
    associatedtype GroupNameType: TypedGroupName
    associatedtype ValueType: Decodable
    static var name: String { get }

    init()
    init(groupName: GroupNameType?, value: ValueType?)
}

extension TypedExperiment {
    public var groupName: GroupNameType? {
        get { nil }
        set { }
    }

    public var value: ValueType? {
        get { nil }
        set { }
    }
    
    public var name: String {
        Self.name
    }

    public init() {
        self.init(groupName: nil, value: nil)
    }

    public init(_ groupName: GroupNameType, _ value: ValueType) {
        self.init(groupName: groupName, value: value)
    }
}
