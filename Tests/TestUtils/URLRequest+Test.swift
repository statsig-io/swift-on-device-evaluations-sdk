import Foundation
import OHHTTPStubsSwift

extension URLRequest {
    public func httpBodyAsDictionary() -> [String: Any]? {
        guard let httpBody = ohhttpStubs_httpBody else {
            return nil
        }

        return try? JSONSerialization
            .jsonObject(with: httpBody, options: []) as? [String: Any]
    }
}
