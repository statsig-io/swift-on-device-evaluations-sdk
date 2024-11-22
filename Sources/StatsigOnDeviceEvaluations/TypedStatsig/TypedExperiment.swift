import Foundation

public protocol TypedGroupName {
    init?(rawValue: String)
}

public struct TypedNoValue: Decodable {}

internal let InvalidTypedExperimentSubclassError: String = "InvalidTypedExperimentSubclass"

open class TypedExperiment<G: TypedGroupName, V: Decodable> {
    public private(set) var name: String
    public private(set) var isMemoizable: Bool
    public private(set) var memoUnitIdType: String
    public private(set) var group: G?
    public private(set) var value: V?

    public required init() {
        self.name = InvalidTypedExperimentSubclassError
        self.isMemoizable = true
        self.memoUnitIdType = "userID"
    }

    public init(
        _ name: String,
        isMemoizable: Bool = false,
        memoUnitIdType: String = "userID"
    ) {
        self.name = name
        self.isMemoizable = isMemoizable
        self.memoUnitIdType = memoUnitIdType
    }
    
    internal func new() -> Self {
        let inst = Self.init()
        inst.name = self.name
        inst.isMemoizable = self.isMemoizable
        inst.memoUnitIdType = self.memoUnitIdType
        return inst
    }

    internal func clone() -> Self {
        let inst = self.new()
        inst.value = self.value
        inst.group = self.group
        return inst
    }

    internal func trySetGroupFromString(_ input: String?) {
        guard let input = input else {
            return
        }
        
        group = G.init(rawValue: input)
    }
    
    internal func trySetValueFromData(_ input: Data?) {
        guard let input = input else {
            return
        }

        let decoder = JSONDecoder()
        value = try? decoder.decode(V.self, from: input)
    }
}

open class TypedExperimentWithoutValue<G: TypedGroupName>: TypedExperiment<G, TypedNoValue> {}
