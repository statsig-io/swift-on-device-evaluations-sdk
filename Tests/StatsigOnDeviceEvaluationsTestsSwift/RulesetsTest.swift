import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

final class RulesetsTest: QuickSpec {
    override class func spec() {
        let user = StatsigUser(userID: "9")
        user.appVersion = "1.3"
        user.userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1"
        user.ip = "1.0.0.0"
        user.locale = "en_US"

        describe("Rulesets") {
            let results = TestResources.getJson("RulesetsResults")
            let gates = results["feature_gates"] as! [String: [String: Any]]
            let configs = results["dynamic_configs"] as! [String: [String: Any]]
            let layers = results["layer_configs"] as! [String: [String: Any]]
            let statsig = Statsig.init()

            beforeSuite {
                NetworkStubs.stubEndpoint(
                    endpoint: "download_config_specs",
                    resource: "RulesetsDownloadConfigsSpecs",
                    times: 1
                )

                waitUntil { done in
                    statsig.initialize("client-key") { err in
                        done()
                    }
                }
            }

            for (key, value) in gates {
                it("is correct for gate \(key)") {
                    let gate = statsig.getFeatureGate(key, user)

                    expect(gate.name).to(equal(key))
                    expect(gate.ruleID).to(equal(value["rule_id"] as? String))
                    expect(gate.value).to(equal(value["value"] as? Bool))
                }
            }


            for (key, value) in configs {
                it("is correct for config \(key)") {
                    let config = statsig.getDynamicConfig(key, user)

                    expect(config.name).to(equal(key))
                    expect(config.ruleID).to(equal(value["rule_id"] as? String))
                    expect(config.value as NSDictionary)
                        .to(equal(value["value"] as? NSDictionary))
                }
            }

            for (key, value) in layers {
                it("is correct for layer \(key)") {
                    let layer = statsig.getLayer(key, user)

                    expect(layer.name).to(equal(key))
                    expect(layer.ruleID).to(equal(value["rule_id"] as? String))
                    expect(layer.value as NSDictionary)
                        .to(equal(value["value"] as? NSDictionary))
                }
            }
        }
    }
}
