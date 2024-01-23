import Foundation

extension Dictionary {
    func toJsonString() -> String? {
        if let data = toJsonData() {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    func toJsonData() -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else {
            return nil
        }

        do {
            return try JSONSerialization.data(withJSONObject: self, options: [])
        } catch {
            print("[Statsig]: Error converting Dictionary to JSON: \(error.localizedDescription)")
        }

        return nil
    }
}
