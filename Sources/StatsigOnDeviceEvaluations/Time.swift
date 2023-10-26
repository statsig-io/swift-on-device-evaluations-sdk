import Foundation

public class Time {
    public static func now() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
