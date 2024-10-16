import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

func getTestDcsWithTimeField(_ res: String, _ time: Int) -> NSString {
    var json = TestResources.getJson(res)
    json["time"] = time
    return String(data: try! JSONSerialization.data(withJSONObject: json), encoding: .utf8)! as NSString
}

final class SynchronousInitTest: QuickSpec {
    override class func spec() {
        describe("SynchronousInit") {
            let user = StatsigUser(userID: "a-user")

            func primeCache() {
                NetworkStubs.clearAllStubs()

                NetworkStubs.stubEndpoint(
                    endpoint: "download_config_specs",
                    resource: "RulesetsDownloadConfigsSpecs"
                )
                
                let client = Statsig()
                waitUntil { done in
                    client.initialize("client-key") { _ in done() }
                }
                
                client.shutdown()
                
                NetworkStubs.clearAllStubs()
            }
            
            it("uses cache if newer and useNewerCacheValuesOverProvidedValues is true") {
                primeCache()
                
                let opts = StatsigOptions()
                opts.useNewerCacheValuesOverProvidedValues = true

                let dcs = getTestDcsWithTimeField("EmptyDcs", 123)
                let client = Statsig()
                let _ = client.initializeSync("client-key", initialSpecs: dcs, options: opts)
                
                let gate = client.getFeatureGate("test_public", user)
                expect(gate.evaluationDetails.reason).to(equal("Cache"))
            }
            
            it("uses bootstrap if useNewerCacheValuesOverProvidedValues is false") {
                primeCache()

                let dcs = getTestDcsWithTimeField("RulesetsDownloadConfigsSpecs", 123)
                let client = Statsig()
                let _ = client.initializeSync("client-key", initialSpecs: dcs)
                
                let gate = client.getFeatureGate("test_public", user)
                expect(gate.evaluationDetails.reason).to(equal("Bootstrap"))
            }
            
            it("uses bootstrap if newer") {
                primeCache()
                
                let opts = StatsigOptions()
                opts.useNewerCacheValuesOverProvidedValues = true

                let dcs = getTestDcsWithTimeField("RulesetsDownloadConfigsSpecs", Int.max)
                let client = Statsig()
                let _ = client.initializeSync("client-key", initialSpecs: dcs, options: opts)
                
                let gate = client.getFeatureGate("test_public", user)
                expect(gate.evaluationDetails.reason).to(equal("Bootstrap"))
            }
        }
    }
}
