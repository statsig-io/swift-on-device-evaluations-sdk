import Foundation
import CommonCrypto

extension String {
    func hashSpecName(_ hashUsed: String?) -> String {
        if hashUsed == "none" {
            return self
        }

        if hashUsed == "djb2" {
            return self.djb2()
        }

        return self.sha256()
    }

    func sha256() -> String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest).base64EncodedString()
    }

    func djb2() -> String {
        var hash: Int32 = 0
        for c in self.utf16 {
            hash = (hash << 5) &- hash &+ Int32(c)
            hash = hash & hash
        }

        return String(format: "%u", UInt32(bitPattern: hash))

    }
    
    func toJson() -> JsonValue? {
        return try? JSONDecoder().decode(JsonValue.self, from: self.data(using: .utf8)!)
    }
}
