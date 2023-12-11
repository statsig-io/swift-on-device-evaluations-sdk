import Quick
import Nimble
import XCTest
import StatsigTestUtils

@testable import StatsigOnDeviceEvaluations

final class UserCreationTest: QuickSpec {
    override class func spec() {
        describe("UserCreation") {
            it("sets values with direct assignment") {
                let user = StatsigUser(userID: "")

                user.customIDs = ["employeeID": "an-employee"]
                user.email = "a@email.com"
                user.ip = "10.0.0.1"
                user.userAgent = "a-user-agent"
                user.country = "NZ"
                user.locale = "en_NZ"
                user.appVersion = "1.2.3"
                user.custom = StatsigUserValueMap(["a-custom": "value"])
                user.privateAttributes =  StatsigUserValueMap(["secret": 1])

                expect(user.email).to(equal("a@email.com"))
                expect(user.ip).to(equal("10.0.0.1"))
                expect(user.userAgent).to(equal("a-user-agent"))
                expect(user.country).to(equal("NZ"))
                expect(user.locale).to(equal("en_NZ"))
                expect(user.appVersion).to(equal("1.2.3"))

                let custom = user.custom.values
                expect(custom["a-custom"] as? String).to(equal("value"))

                let attribs = user.privateAttributes.values
                expect(attribs["secret"] as? Int).to(equal(1))
            }

            it("sets values with the initializer") {
                let user = StatsigUser(
                    userID: "a-user",
                    customIDs: ["employeeID": "an-employee"],
                    email: "a@email.com",
                    ip: "10.0.0.1",
                    userAgent: "a-user-agent",
                    country: "NZ",
                    locale: "en_NZ",
                    appVersion: "1.2.3",
                    custom: ["a-custom": "value"],
                    privateAttributes: ["secret": 1]
                )

                expect(user.email).to(equal("a@email.com"))
                expect(user.ip).to(equal("10.0.0.1"))
                expect(user.userAgent).to(equal("a-user-agent"))
                expect(user.country).to(equal("NZ"))
                expect(user.locale).to(equal("en_NZ"))
                expect(user.appVersion).to(equal("1.2.3"))

                let custom = user.custom.values
                expect(custom["a-custom"] as? String).to(equal("value"))

                let attribs = user.privateAttributes.values
                expect(attribs["secret"] as? Int).to(equal(1))
            }
        }
    }
}
