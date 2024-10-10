import Foundation

@objc public class TestResources: NSObject {
    @objc public static func getJson(_ name: String) -> [String: Any] {
        let url = TestResources.getUrl(name)
        let json = try! Data(contentsOf: url)
        return try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
    }

    @objc public static func getUrl(_ name: String) -> URL {
        return Bundle.module.url(
            forResource: "\(name)", withExtension: "json")!
    }
    
    @objc public static func getContents(_ name: String) -> String {
        let url = TestResources.getUrl(name)
        let json = try! Data(contentsOf: url)
        return String(data: json, encoding: .utf8)!
    }
}
