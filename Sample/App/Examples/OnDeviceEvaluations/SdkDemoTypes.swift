import Foundation
import StatsigOnDeviceEvaluations

@objc class SdkDemoGates: NSObject {
    @objc static let aGate = TypedGateName("a_gate")
    @objc static let partialGate = TypedGateName("partial_gate")
}

class SdkDemoExperiments {
    static let AnExperiment = SdkDemoTypedAnExperiment.self
    static let AnotherExperiment = SdkDemoTypedAnotherExperiment.self
}

struct SdkDemoTypedAnExperiment: TypedExperimentMemoizedByUserID {
    static var name = "an_experiment"
    
    var groupName: SdkDemoTypedAnExperimentGroup?
    enum SdkDemoTypedAnExperimentGroup: String, TypedGroupName {
        case control = "Control"
        case test = "Test"
    }

    var value: TypedNoValue?
}

struct SdkDemoTypedAnotherExperiment: TypedExperiment {
    static var name = "another_experiment"
    
    var groupName: SdkDemoTypedAnotherExperimentGroup?
    enum SdkDemoTypedAnotherExperimentGroup: String, TypedGroupName {
        case control = "Control"
        case testOne = "Test One"
        case testTwo = "Test Two"
    }
    
    var value: AnotherExperimentValue?
    struct AnotherExperimentValue: Decodable {
        let aString: String
        let aBool: Bool

        enum CodingKeys: String, CodingKey {
            case aString = "a_string"
            case aBool = "a_bool"
        }
    }
}
