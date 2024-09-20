import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

final class LocalOverrideTest: QuickSpec {
    override class func spec() {
        let user = StatsigUser(userID: "testUser")
        let overrides = LocalOverrideAdapter()
        let opts = StatsigOptions()
        opts.overrideAdapter = overrides
        let statsig = Statsig.init()
        
        describe("Local Overrides") {
            beforeSuite {
                NetworkStubs.stubEndpoint(
                    endpoint: "download_config_specs",
                    resource: "RulesetsDownloadConfigsSpecs",
                    times: 1
                )
                waitUntil { done in
                    statsig.initialize("client-key", options: opts) { err in
                        done()
                    }
                }
            }
            
            it("Gate Overrides") {
                overrides.setGate(user, "overridden_gate", FeatureGate.create("overridden_gate", true))
                let gate = statsig.checkGate("overridden_gate", user)
                expect(gate).to(equal(true))
            }
            
            it("DynamicConfig Overrides") {
                overrides.setDynamicConfig(user, "overridden_config", DynamicConfig.create("overridden_config", ["key": "val"]))
                let config = statsig.getDynamicConfig("overridden_config", user)
                expect(config.value["key"] as? String).to(equal("val"))
            }
            
            it("Experiment Overrides") {
                overrides.setExperiment(user, "overridden_exp", Experiment.create("overridden_exp", ["key": "val"]))
                let experiment = statsig.getExperiment("overridden_exp", user)
                expect(experiment.value["key"] as? String).to(equal("val"))
            }
            
            it("Layer Overrides") {
                overrides.setLayer(user, "overridden_layer", Layer.create("overridden_layer", ["key": "val"]))
                let layer = statsig.getLayer("overridden_layer", user)
                expect(layer.value["key"] as? String).to(equal("val"))
            }
        }
    }
}
