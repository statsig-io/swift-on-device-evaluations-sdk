import Foundation

@objc public class TypedGateName: NSObject {
    public let value: String
    public let isMemoizable: Bool
    public let memoUnitIdType: String
    
    public init(
        _ value: String,
        isMemoizable: Bool = false,
        memoUnitIdType: String = "userID"
    ) {
        self.value = value
        self.isMemoizable = isMemoizable
        self.memoUnitIdType = memoUnitIdType
    }
}
