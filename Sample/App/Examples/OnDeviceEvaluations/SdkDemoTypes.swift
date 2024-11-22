import Foundation
import StatsigOnDeviceEvaluations

@objc class SdkDemoGates: NSObject {
    @objc static let aGate = TypedGateName("a_gate", isMemoizable: true)
    @objc static let partialGate = TypedGateName("partial_gate")
}

public enum SdkDemoSimpleGroupName: String, TypedGroupName {
    case control = "Control"
    case test = "Test"
}

class SdkDemoExperiments {
    class AnExperiment: TypedExperiment<SdkDemoSimpleGroupName, TypedNoValue> {
        init() { super.init("an_experiment", isMemoizable: true) }
    }
    
    enum SdkDemoTypedAnotherExperimentGroup: String, TypedGroupName {
        case control = "Control"
        case testOne = "Test One"
        case testTwo = "Test Two"
    }
    
    struct AnotherExperimentValue: Decodable {
        let aString: String
        let aBool: Bool

        enum CodingKeys: String, CodingKey {
            case aString = "a_string"
            case aBool = "a_bool"
        }
    }
    
    class AnotherExperiment: TypedExperiment<SdkDemoSimpleGroupName, AnotherExperimentValue> {
        init() { super.init("another_experiment") }
    }
}
