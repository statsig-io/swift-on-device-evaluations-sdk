import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

struct TestExperiment: TypedExperiment {
    static var name = "experiment_with_many_params"

    var groupName: Group?
    var value: TypedNoValue?
    
    enum Group: String, TypedGroupName {
        case control = "Control"
        case test = "Test"
        case test2 = "Test #2"
    }
}

enum SimpleGroup: String, TypedGroupName {
    case control = "Control"
    case test = "Test"
}

struct TestMemoExperiment: TypedExperiment {
    static var name = "test_exp_5050_targeting"
    static var isMemoizable = true
    static var memoUnitIdType = "userID"
    
    var groupName: SimpleGroup?
    var value: TypedNoValue?
}

struct TestBadGroupNameExp: TypedExperiment {
    static var name = "experiment_with_many_params"

    var groupName: Group?
    var value: TypedNoValue?
    
    enum Group: String, TypedGroupName {
        case bad = "Bad"
        case invalid = "Invalid"
    }
}

struct TestBadValueExp: TypedExperiment {
    static var name = "experiment_with_many_params"
    struct MyValues: Codable {
        let foo: String
    }

    var groupName: SimpleGroup?
    var value: MyValues?
}

final class StatsigTypedExperimentTest: QuickSpec {
    override class func spec() {
        describe("StatsigTypedExperiment") {
            var requests: [URLRequest] = []
            var client: Statsig!
            
            beforeEach {
                NetworkStubs.clearAllStubs()

                NetworkStubs.stubEndpoint(
                    endpoint: "download_config_specs",
                    resource: "RulesetsDownloadConfigsSpecs") { req in
                        if req.url?.absoluteString.contains("http://StatsigTypedExperiment/v1/download_config_specs") != true {
                            return
                        }
                        
                        requests.append(req)
                    }

                client = Statsig()
                waitUntil { done in
                    let opts = StatsigOptions()
                    opts.configSpecAPI = "http://StatsigTypedExperiment/v1/download_config_specs"
                    opts.eventLoggingAPI = "http://StatsigTypedExperiment/v1/rgstr"
                    client.initialize("client-key", options: opts) { err in
                        done()
                    }
                }

                requests = []
            }

            it("is switchable on group names") {
                let user = StatsigUser(userID: "user-in-test")
                let testExperiment = client.typed.getExperiment(TestExperiment.self, user)

                switch testExperiment.groupName {
                case .control:
                    assert(false)
                case .test:
                    assert(true)
                case .test2:
                    assert(false)
                default:
                    assert(false)
                }
            }
            
            it("works with complex group names") {
                let user = StatsigUser(userID: "user-in-test-2")
                let testExperiment = client.typed.getExperiment(TestExperiment.self, user)
                expect(testExperiment.groupName).to(equal(.test2))
            }
            
            it("memoizes experiments") {
                let user = StatsigUser(userID: "user-in-test")
                let exp1 = client.typed.getExperiment(TestMemoExperiment.self, user)
                
                let dcs = getTestDcsWithTimeField("EmptyDcs", 123)
                _ = client.updateSync(updatedSpecs: dcs)
                
                let exp2 = client.typed.getExperiment(TestMemoExperiment.self, user)
                let exp3 = client.getExperiment(TestMemoExperiment.name)
                
                expect(exp1.groupName).to(equal(.test))
                expect(exp2.groupName).to(equal(.test))
                expect(exp3.groupName).to(beNil())
            }
            
            it("works with the global user") {
                client.setGlobalUser(StatsigUser(userID: "user-in-test"))
                let testExperiment = client.typed.getExperiment(TestExperiment.self)
                expect(testExperiment.groupName).to(equal(.test))
            }
            
            it("handles incorrect group names") {
                let user = StatsigUser(userID: "user-in-test")
                let listener = TestListener()
                client.addListener(listener)
                
                let exp = client.typed.getExperiment(TestBadGroupNameExp.self, user)
                expect(exp.groupName).to(beNil())
                
                expect(listener.lastErrorMessage()).to(equal("Failed to convert group name 'Test' to type 'Group'"))
                expect(listener.events).to(haveCount(1))
            }
            
            it("handles incorrect json values") {
                let user = StatsigUser(userID: "user-in-test")
                let listener = TestListener()
                client.addListener(listener)
                
                let exp = client.typed.getExperiment(TestBadValueExp.self, user)
                expect(exp.groupName).to(equal(.test))
        
                let msg = listener.lastErrorMessage()
                expect(msg).to(contain("Failed to deserialize json value"))
                expect(msg).to(contain("to type 'MyValues'"))
                expect(listener.events).to(haveCount(1))
            }
            
            it("sends experiment exposure events") {
                let user = StatsigUser(userID: "user-in-test")
                let _ = client.typed.getExperiment(TestExperiment.self, user)

                let events = flushAndCaptureEvents(client)
                expect(events).to(haveCount(1))
                expect(events.first!["eventName"] as? String).to(equal("statsig::config_exposure"))
            }
            
            it("disables experiment exposure events when option set") {
                let user = StatsigUser(userID: "user-in-test")
                let _ = client.typed.getExperiment(TestExperiment.self, user, .disabledExposures())

                let events = flushAndCaptureEvents(client)
                expect(events).to(haveCount(0))
            }
        }
    }
}
