import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

final class ExposureLoggingTest: QuickSpec {
    override class func spec() {
        describe("ExposureLogging") {
            let user = StatsigUser(userID: "a-user")
            var logRequest: URLRequest?

            beforeSuite {
                NetworkStubs.clearAllStubs()

                NetworkStubs.stubEndpoint(
                    endpoint: "download_config_specs",
                    resource: "RulesetsDownloadConfigsSpecs",
                    times: 1
                )

                let client = StatsigClient()

                waitUntil { done in
                    client.initialize("client-key") { err in
                        done()
                    }
                }

                let _ = client.checkGate("test_public", user)
                let _ = client.getDynamicConfig("test_email_config", user)
                let _ = client.getExperiment("test_experiment_no_targeting", user)
                let _ = client.getLayer("layer_with_many_params", user)

                waitUntil { done in
                    NetworkStubs.stubEndpoint(
                        endpoint: "rgstr",
                        resource: "Success",
                        times: 1
                    ) { request in
                        logRequest = request
                        done()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        client.flushEvents()
                    }

                }
            }

            it("flushes events") {
                let body = logRequest?.httpBodyAsDictionary()
                expect(body?["events"] as? [Any]).to(haveCount(4))
            }
        }
    }
}
