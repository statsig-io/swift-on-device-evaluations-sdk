import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

func setup(_ options: StatsigOptions? = nil) -> Statsig {
    NetworkStubs.clearAllStubs()

    NetworkStubs.stubEndpoint(
        endpoint: "download_config_specs",
        resource: "RulesetsDownloadConfigsSpecs",
        times: 1
    )

    let client = Statsig()

    waitUntil { done in
        client.initialize("client-key", options: options) { err in
            done()
        }
    }

    return client
}

func flushAndCaptureEvents(_ client: Statsig) -> [[String: Any]] {
    var logRequest: URLRequest?

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
    
    let body = logRequest?.httpBodyAsDictionary()
    let events: [[String: Any]] = (body?["events"] as? [[String: Any]]) ?? []
    return events.filter { event in
        return event["eventName"] as? String != "statsig::diagnostics"
    }
}

final class EnvironmentLoggingTest: QuickSpec {
    override class func spec() {
        describe("EnvironmentLogging") {
            it("logs global environment") {
                let opts = StatsigOptions()
                opts.environment = StatsigEnvironment()
                opts.environment.tier = "staging"
                
                let client = setup(opts)
                let user = StatsigUser(userID: "a-user")
                let _ = client.checkGate("test_public", user)
                
                let events = flushAndCaptureEvents(client)
                let loggedUser = events.first?["user"] as? [String: Any]
                let environment = loggedUser?["statsigEnvironment"] as? [String: Any]
                expect(environment?["tier"] as? String).to(equal("staging"))
            }
            
            it("logs user specific environment") {
                let opts = StatsigOptions()
                opts.environment = StatsigEnvironment(tier: "development")
                
                let client = setup(opts)
                let user = StatsigUser(userID: "a-user")
                user.environment = StatsigEnvironment(tier: "staging")
                
                let _ = client.checkGate("test_public", user)
                
                let events = flushAndCaptureEvents(client)
                let loggedUser = events.first?["user"] as? [String: Any]
                let environment = loggedUser?["statsigEnvironment"] as? [String: Any]
                expect(environment?["tier"] as? String).to(equal("staging"))
            }
        }
    }
}
