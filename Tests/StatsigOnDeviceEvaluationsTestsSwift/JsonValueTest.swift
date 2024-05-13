import Quick
import Nimble
import XCTest

@testable import StatsigOnDeviceEvaluations

final class JsonValueTest: QuickSpec {
    override class func spec() {
        describe("JsonValue") {
            describe("Decoding") {
                it("handles strings") {
                    let value = getDecoded("\"1.2\"")
                    expect(value).to(equal(.string("1.2")))
                    expect(value).to(convertInto(
                        dictionary: nil, array: nil, string: "1.2", double: 1.2
                    ))
                }

                it("handles ints") {
                    let value = getDecoded(12)
                    expect(value).to(equal(.int(12)))
                    expect(value).to(convertInto(
                        dictionary: nil, array: nil, string: "12", double: 12.0
                    ))
                }

                it("handles doubles") {
                    let value = getDecoded(1.2)
                    expect(value).to(equal(.double(1.2)))
                    expect(value).to(convertInto(
                        dictionary: nil, array: nil, string: "1.2", double: 1.2
                    ))
                }

                it("handles bool") {
                    let value = getDecoded(true)
                    expect(value).to(equal(.bool(true)))
                    expect(value).to(convertInto(
                        dictionary: nil, array: nil, string: "true", double: nil
                    ))
                }

                it("handles arrays") {
                    let value = getDecoded("[1]")
                    expect(value).to(equal(.array([.int(1)])))
                    expect(value).to(convertInto(
                        dictionary: nil, array: [.int(1)], string: nil, double: nil
                    ))
                }

                it("handles dictionaries") {
                    let value = getDecoded("{\"key\": 1}")
                    expect(value).to(equal(.dictionary(["key": .int(1)])))
                    expect(value).to(convertInto(
                        dictionary: ["key": 1], array: nil, string: nil, double: nil
                    ))
                }
            }

            describe("Encoding") {
                it("handles strings") {
                    let value = getEncoded(.string("1.2"))
                    expect(value).to(equal("\"1.2\""))
                }

                it("handles ints") {
                    let value = getEncoded(.int(123))
                    expect(value).to(equal("123"))
                }

                it("handles doubles") {
                    let value = getEncoded(.double(1.2))
                    expect(value).to(equal("1.2"))
                }

                it("handles bool") {
                    let value = getEncoded(.bool(true))
                    expect(value).to(equal("true"))
                }

                it("handles arrays") {
                    let value = getEncoded(.array([
                        .bool(false), .int(2), .string("3")
                    ]))
                    expect(value).to(equal("[false,2,\"3\"]"))
                }

                it("handles dictionaries") {
                    let value = getEncoded(.dictionary([
                        "foo": .int(1)
                    ]))
                    expect(value).to(equal("{\"foo\":1}"))
                }
            }
        }
    }
}

fileprivate class TestDecodable: Decodable {
    let value: JsonValue?
}


fileprivate func getDecoded(_ input: Any) -> JsonValue? {
    let json = "{\"value\": \(input)}"
    let data = json.data(using: .utf8)!
    return try! JSONDecoder()
        .decode(TestDecodable.self, from:data)
        .value
}

fileprivate func getEncoded(_ input: JsonValue) -> String? {
    let encoder = JSONEncoder()
    let data = try! encoder.encode(input)
    return String(data: data, encoding: .utf8)
}

fileprivate func convertInto(
    dictionary: NSDictionary?,
    array: [JsonValue]?,
    string: String?,
    double: Double?
) -> Matcher<JsonValue> {
    Matcher.define(matcher: { actualExpression, msg in
        let actual = try! actualExpression.evaluate()
        if actual?.serializeToDictionary() as NSDictionary? != dictionary {
            return MatcherResult(
                status: .fail,
                message: .fail(
                    "Invalid Dictionary. Expected \(String(describing: dictionary)), got \(String(describing: actual?.serializeToDictionary()))"
                )
            )
        }

        if actual?.asJsonArray() != array {
            return MatcherResult(
                status: .fail,
                message: .fail(
                    "Invalid Array. Expected \(String(describing: array)), got \(String(describing: actual?.asJsonArray()))"
                )
            )
        }

        if actual?.asString() != string {
            return MatcherResult(
                status: .fail,
                message: .fail(
                    "Invalid String. Expected \(String(describing: string)), got \(String(describing: actual?.asString()))"
                )
            )
        }

        if actual?.asDouble() != double {
            return MatcherResult(
                status: .fail,
                message: .fail(
                    "Invalid Double. Expected \(String(describing: double)), got \(String(describing: actual?.asDouble()))"
                )
            )
        }

        return MatcherResult(bool: true, message: msg)
    })
}
