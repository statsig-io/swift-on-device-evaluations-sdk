import Foundation

public protocol TypedGroupName {
    init?(rawValue: String)
}

public struct TypedNoValue: Decodable {}

public protocol TypedExperiment {
    associatedtype GroupNameType: TypedGroupName
    associatedtype ValueType: Decodable
    
    static var name: String { get }
    static var isMemoizable: Bool { get }
    static var memoUnitIdType: String { get }

    init()
    init(groupName: GroupNameType?, value: ValueType?)
}

extension TypedExperiment {
    public static var isMemoizable: Bool {
        return false
    }
    
    public static var memoUnitIdType: String {
        return ""
    }
    
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

    public var isMemoizable: Bool {
        Self.isMemoizable
    }
    
    public var memoUnitIdType: String {
        Self.memoUnitIdType
    }

    public init() {
        self.init(groupName: nil, value: nil)
    }

    public init(_ groupName: GroupNameType, _ value: ValueType) {
        self.init(groupName: groupName, value: value)
    }
}


// MARK: UserID + Memoization

public protocol TypedExperimentMemoizedByUserID: TypedExperiment {}

extension TypedExperimentMemoizedByUserID {
    public static var isMemoizable: Bool {
        return true
    }
    
    public static var memoUnitIdType: String {
        return "userID"
    }
}


// MARK: StableID + Memoization

public protocol TypedExperimentMemoizedByStableID: TypedExperiment {}

extension TypedExperimentMemoizedByStableID {
    public static var isMemoizable: Bool {
        return true
    }
    
    public static var memoUnitIdType: String {
        return "stableID"
    }
}

