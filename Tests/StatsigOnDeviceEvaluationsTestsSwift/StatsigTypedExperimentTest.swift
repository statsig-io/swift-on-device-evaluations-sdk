import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations


enum TestExperimentGroup: String, TypedGroupName {
    case control = "Control"
    case test = "Test"
    case test2 = "Test #2"
}

class TestExperiment: TypedExperiment<TestExperimentGroup, TypedNoValue> {
    required init() { super.init("experiment_with_many_params") }
}

enum SimpleGroup: String, TypedGroupName {
    case control = "Control"
    case test = "Test"
}

class TestMemoExperiment: TypedExperiment<SimpleGroup, TypedNoValue> {
    required init() { super.init("test_exp_5050_targeting", isMemoizable: true) }
}

enum TestBadGroup: String, TypedGroupName {
    case bad = "Bad"
    case invalid = "Invalid"
}

class TestBadGroupNameExp: TypedExperiment<TestBadGroup, TypedNoValue> {
    required init() { super.init("experiment_with_many_params") }
}

struct InvalidValue: Codable {
    let foo: String
}

class TestBadValueExp: TypedExperiment<SimpleGroup, InvalidValue> {
    required init() { super.init("experiment_with_many_params") }
}

let letBasedExperiment = TypedExperimentWithoutValue<SimpleGroup>(
    "experiment_with_many_params",
    isMemoizable: true
)

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
                let testExperiment = client.typed.getExperiment(TestExperiment(), user)

                switch testExperiment.group {
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
                let testExperiment = client.typed.getExperiment(TestExperiment(), user)
                expect(testExperiment.group).to(equal(.test2))
            }
            
            it("memoizes experiments") {
                let user = StatsigUser(userID: "user-in-test")
                let exp1 = client.typed.getExperiment(TestMemoExperiment(), user)
                
                let dcs = getTestDcsWithTimeField("EmptyDcs", 123)
                _ = client.updateSync(updatedSpecs: dcs)
                
                let exp2 = client.typed.getExperiment(TestMemoExperiment(), user)
                let exp3 = client.getExperiment(TestMemoExperiment().name)
                
                expect(exp1.group).to(equal(.test))
                expect(exp2.group).to(equal(.test))
                expect(exp3.groupName).to(beNil())
            }
            
            it("works with the global user") {
                client.setGlobalUser(StatsigUser(userID: "user-in-test"))
                let testExperiment = client.typed.getExperiment(TestExperiment())
                expect(testExperiment.group).to(equal(.test))
            }
            
            it("handles incorrect group names") {
                let user = StatsigUser(userID: "user-in-test")
                let listener = TestListener()
                client.addListener(listener)
                
                let exp = client.typed.getExperiment(TestBadGroupNameExp(), user)
                expect(exp.group).to(beNil())
                
                expect(listener.lastErrorMessage()).to(equal("Failed to convert group name 'Test' to type 'TestBadGroup'"))
                expect(listener.events).to(haveCount(1))
            }
            
            it("handles incorrect json values") {
                let user = StatsigUser(userID: "user-in-test")
                let listener = TestListener()
                client.addListener(listener)
                
                let exp = client.typed.getExperiment(TestBadValueExp(), user)
                expect(exp.group).to(equal(.test))
        
                let msg = listener.lastErrorMessage()
                expect(msg).to(contain("Failed to deserialize json value"))
                expect(msg).to(contain("to type 'InvalidValue'"))
                expect(listener.events).to(haveCount(1))
            }
            
            it("sends experiment exposure events") {
                let user = StatsigUser(userID: "user-in-test")
                let _ = client.typed.getExperiment(TestExperiment(), user)

                let events = flushAndCaptureEvents(client)
                expect(events).to(haveCount(1))
                expect(events.first!["eventName"] as? String).to(equal("statsig::config_exposure"))
            }
            
            it("disables experiment exposure events when option set") {
                let user = StatsigUser(userID: "user-in-test")
                let _ = client.typed.getExperiment(TestExperiment(), user, .disabledExposures())

                let events = flushAndCaptureEvents(client)
                expect(events).to(haveCount(0))
            }
            
            it("clears stored values when cannibalized") {
                let user = StatsigUser(userID: "user-in-test")
                let one = client.typed.getExperiment(TestExperiment(), user)
                let dcs = getTestDcsWithTimeField("EmptyDcs", 123)
                _ = client.updateSync(updatedSpecs: dcs)

                // feed one to two
                let two = client.typed.getExperiment(one, user)
                
                expect(one.group).to(equal(.test))
                expect(two.group).to(beNil())
            }
            
            it("clones instances") {
                let user = StatsigUser(userID: "user-in-test")
                let experiment = TestExperiment()
                let result = client.typed.getExperiment(experiment, user)
                
                expect(experiment).notTo(beIdenticalTo(result))
            }
            
            it("clones memoed instances") {
                let user = StatsigUser(userID: "user-in-test")
                let one = client.typed.getExperiment(letBasedExperiment, user)
                expect(one.group).to(equal(.test))
                
                let dcs = getTestDcsWithTimeField("EmptyDcs", 123)
                _ = client.updateSync(updatedSpecs: dcs)
                
                let two = client.typed.getExperiment(letBasedExperiment, user)
                expect(two.group).to(equal(.test))
                
                expect(one).notTo(beIdenticalTo(two))
            }
        }
    }
}
