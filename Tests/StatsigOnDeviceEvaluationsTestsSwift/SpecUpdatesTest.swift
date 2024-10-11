import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

final class SpecUpdatesTest: QuickSpec {
    override class func spec() {
        describe("SpecUpdates") {
            var requests: [URLRequest] = []
            var client: Statsig!
            
            beforeEach {
                NetworkStubs.clearAllStubs()

                NetworkStubs.stubEndpoint(
                    endpoint: "download_config_specs",
                    resource: "RulesetsDownloadConfigsSpecs") { req in
                        if req.url?.absoluteString.contains("http://SpecUpdatesTest/v1/download_config_specs") != true {
                            return
                        }
                        
                        requests.append(req)
                    }

                client = Statsig()
                waitUntil { done in
                    let opts = StatsigOptions()
                    opts.configSpecAPI = "http://SpecUpdatesTest/v1/download_config_specs"
                    client.initialize("client-key", options: opts) { err in
                        done()
                    }
                }

                requests = []
            }
            
            it("hits dcs when update is called") {
                waitUntil { done in
                    client.update { error in
                        done()
                    }
                }

                expect(requests.count).to(equal(1))
            }
            
            it("bg updates makes requests to dcs") {
                client.minBackgroundSyncInterval = 0.000001
            
                let _ = client.scheduleBackgroundUpdates(intervalSeconds: 0.01)
                expect(requests.count).toEventually(beGreaterThan(2), timeout: .milliseconds(500))
            }
            
            it("cancels bg updates") {
                let handle = client.scheduleBackgroundUpdates(intervalSeconds: 0.2)
                handle?.cancel()
                
                waitUntil { done in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        done()
                    }
                }
                
                expect(requests.isEmpty).to(beTrue())
            }
            
            it("cancels bg updates on shutdown") {
                let handle = client.scheduleBackgroundUpdates()
                client.shutdown()
                
                expect(handle?.isCancelled).to(beTrue())
            }
            
            it("cancels previous timers on repeat schedules") {
                let handle1 = client.scheduleBackgroundUpdates(intervalSeconds: 0.1)
                let handle2 = client.scheduleBackgroundUpdates(intervalSeconds: 0.1)

                expect(handle1?.isCancelled).to(beTrue())
                expect(handle2?.isCancelled).to(beFalse())
            }
            
            it("updates from bootstrap") {
                let client = Statsig()
                let user = StatsigUser(userID: "a-user")
                
                let _ = client.initializeSync("client-key", initialSpecs: "{}" as NSString)
                expect(client.checkGate("test_public", user)).to(beFalse())
                
                let values = TestResources.getContents("RulesetsDownloadConfigsSpecs")
                let _ = client.updateSync(updatedSpecs: values as NSString)
                
                expect(client.checkGate("test_public", user)).to(beTrue())
            }
        }
    }
}
