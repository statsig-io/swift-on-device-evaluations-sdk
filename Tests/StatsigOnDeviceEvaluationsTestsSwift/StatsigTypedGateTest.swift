import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

@objc class TestGates: NSObject {
    @objc static let simple = TypedGateName("test_public")
    @objc static let memoized = TypedGateName("test_50_50",  isMemoizable: true)
}

final class StatsigTypedGateTest: QuickSpec {
    override class func spec() {
        describe("StatsigTypedGate") {
            var requests: [URLRequest] = []
            var client: Statsig!
            
            beforeEach {
                NetworkStubs.clearAllStubs()

                NetworkStubs.stubEndpoint(
                    endpoint: "download_config_specs",
                    resource: "RulesetsDownloadConfigsSpecs") { req in
                        if req.url?.absoluteString.contains("http://StatsigTypedGate/v1/download_config_specs") != true {
                            return
                        }
                        
                        requests.append(req)
                    }

                client = Statsig()
                waitUntil { done in
                    let opts = StatsigOptions()
                    opts.configSpecAPI = "http://StatsigTypedGate/v1/download_config_specs"
                    opts.eventLoggingAPI = "http://StatsigTypedGate/v1/rgstr"
                    client.initialize("client-key", options: opts) { err in
                        done()
                    }
                }

                requests = []
            }

            it("gets gate results") {
                let user = StatsigUser(userID: "user-in-test")
                let gate = client.typed.getFeatureGate(TestGates.simple, user)
                expect(gate.value).to(beTrue())
            }
            
            it("memoizes gates") {
                let user = StatsigUser(userID: "user-in-test")
                let gate1 = client.typed.getFeatureGate(TestGates.memoized, user)
                
                let dcs = getTestDcsWithTimeField("EmptyDcs", 123)
                _ = client.updateSync(updatedSpecs: dcs)
                
                let gate2 = client.typed.getFeatureGate(TestGates.memoized, user)
                let gate3 = client.getFeatureGate(TestGates.memoized.value, user)
                
                expect(gate1.value).to(beTrue())
                expect(gate2.value).to(beTrue())
                expect(gate3.value).to(beFalse())
            }
            
            it("works with the global user") {
                client.setGlobalUser(StatsigUser(userID: "user-in-test"))
                let gate = client.typed.getFeatureGate(TestGates.simple)
                expect(gate.value).to(beTrue())
            }
            
            it("sends gate exposure events") {
                let user = StatsigUser(userID: "user-in-test")
                let _ = client.typed.getFeatureGate(TestGates.simple, user)
                let _ = client.typed.checkGate(TestGates.simple, user)

                let events = flushAndCaptureEvents(client)
                expect(events).to(haveCount(2))
                expect(events[0]["eventName"] as? String).to(equal("statsig::gate_exposure"))
                expect(events[1]["eventName"] as? String).to(equal("statsig::gate_exposure"))
            }
            
            it("disables gate exposure events when option set") {
                let user = StatsigUser(userID: "user-in-test")
                let _ = client.typed.getFeatureGate(TestGates.simple, user, .disabledExposures())
                let _ = client.typed.checkGate(TestGates.simple, user, .disabledExposures())

                let events = flushAndCaptureEvents(client)
                expect(events).to(haveCount(0))
            }
        }
    }
}
