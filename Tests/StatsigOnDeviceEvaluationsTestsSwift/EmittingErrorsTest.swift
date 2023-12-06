import Quick
import Nimble
import XCTest
import StatsigTestUtils

import StatsigOnDeviceEvaluations

class TestListener: StatsigListening {
    var lastErrorData: [String: Any] = [:]

    func onStatsigClientEvent(
        _ event: StatsigClientEvent,
        _ eventData: [String : Any]
    ) {
        if event == .error {
            lastErrorData = eventData
        }
    }

    func lastErrorMessage() -> String? {
        lastErrorData["message"] as? String
    }
}

final class EmittingErrorsTest: QuickSpec{
    override class func spec() {
        describe("EmittingErrors") {
            var client: Statsig!
            var listener: TestListener!

            beforeSuite {
                listener = TestListener()
            }

            describe("Calls before initialize") {
                beforeEach {
                    client = Statsig()
                    client.addListener(listener)
                }

                let cases = [
                    ({ _ = client.checkGate("a_gate") }, "getFeatureGate(_:_:)"),
                    ({ _ = client.getFeatureGate("a_gate") }, "getFeatureGate(_:_:)"),
                    ({ _ = client.getDynamicConfig("a_dynamic_config") }, "getDynamicConfig(_:_:)"),
                    ({ _ = client.getExperiment("an_experiment") }, "getExperiment(_:_:)"),
                    ({ _ = client.getLayer("a_layer") }, "getLayer(_:_:)"),
                ]

                cases.forEach { (action, expected) in
                    it("emits on \(expected)") {
                        action()

                        expect(listener.lastErrorMessage())
                            .to(equal("\(expected) called before Statsig.initialize."))
                    }
                }
            }

            describe("Calls without providing StatsigUser") {
                beforeEach {
                    client = Statsig()
                    client.addListener(listener)

                    _ = client.initializeSync("client-key", initialSpecs: "" as NSString)
                }

                let cases = [
                    ({ _ = client.checkGate("a_gate") }, "getFeatureGate(_:_:)"),
                    ({ _ = client.getFeatureGate("a_gate") }, "getFeatureGate(_:_:)"),
                    ({ _ = client.getDynamicConfig("a_dynamic_config") }, "getDynamicConfig(_:_:)"),
                    ({ _ = client.getExperiment("an_experiment") }, "getExperiment(_:_:)"),
                    ({ _ = client.getLayer("a_layer") }, "getLayer(_:_:)"),
                ]

                cases.forEach { (action, expected) in
                    it("emits on \(expected)") {
                        action()

                        expect(listener.lastErrorMessage())
                            .to(equal("No user given when calling \(expected). Please provide a StatsigUser or call setGlobalUser."))
                    }
                }
            }

        }
    }
}
