import Foundation

import OHHTTPStubs
import OHHTTPStubsSwift

@objc public class NetworkStubs: NSObject {
    @objc(stubEndpoint:withResource:times:)
    public static func stubEndpoint(
        endpoint: String,
        resource: String,
        times: Int = -1
    ) {
        stubEndpoint(
            endpoint: endpoint,
            resource: resource,
            times: times,
            onRequest: nil
        )
    }

    public static func clearAllStubs() {
        HTTPStubs.removeAllStubs()
    }

    public static func stubEndpoint(
        endpoint: String,
        resource: String,
        times: Int = -1,
        onRequest: ((URLRequest) -> Void)? = nil
    ) {
        var path: String!

        switch endpoint {
        case "download_config_specs":
            path = "/v1/download_config_specs"
        case "rgstr":
            path = "/v1/rgstr"
        default:
            assert(false, "Invalid Endpoint \(endpoint)")
        }

        var calls = 0
        var descriptor: HTTPStubsDescriptor!
        descriptor = stub(condition: pathStartsWith(path)) { req in
            if let onRequest = onRequest {
                onRequest(req)
            }

            let response = TestResources.getJson(resource)

            calls += 1
            if calls == times {
                HTTPStubs.removeStub(descriptor)
            }

            return HTTPStubsResponse(
                jsonObject: response,
                statusCode: 200,
                headers: nil
            )
        }
    }
}
