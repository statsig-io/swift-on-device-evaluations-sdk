import Foundation
import StatsigOnDeviceEvaluations

public enum SdkDemoExperimentName: String {
    case empty = ""
    case anExperiment = "an_experiment"
    case anotherExperiment = "another_experiment"
}

public enum SdkDemoDynamicConfigName: String {
    case empty = ""
    case aDynamicConfig = "a_dynamic_config"
}

@objc class SdkDemoGates: NSObject {
    @objc static let aGate = TypedGateName("a_gate")
    @objc static let partialGate = TypedGateName("partial_gate")
}

class SdkDemoExperiments {
    static let AnExperiment = SdkDemoTypedAnExperiment.self
    static let AnotherExperiment = SdkDemoTypedAnotherExperiment.self
}

struct SdkDemoTypedAnExperiment: TypedExperiment {
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
