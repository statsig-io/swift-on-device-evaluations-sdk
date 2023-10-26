import Foundation

import Nimble
import Quick
import OHHTTPStubs
#if !COCOAPODS
import OHHTTPStubsSwift
#endif
@testable import StatsigPrecomputedEvaluations


let userA = StatsigUser(
    userID: "user-a",
    customIDs: ["workID": "employee-a", "projectID": "project-a"],
    email: "user-a@statsig.io",
    ip: "1.2.3.4",
    country: "US",
    locale:"en_US",
    appVersion: "3.2.1",
    custom: ["isVerified": true, "hasPaid": false],
    privateAttributes: ["age": 34, "secret": "shhh"]
)

let userAAgain = StatsigUser(
    userID: "user-a",
    customIDs: [ "projectID": "project-a", "workID": "employee-a"],
    email: "user-a@statsig.io",
    ip: "1.2.3.4",
    country: "US",
    locale:"en_US",
    appVersion: "3.2.1",
    custom: ["hasPaid": false, "isVerified": true],
    privateAttributes: ["secret": "shhh", "age": 34]
)

let userB = StatsigUser(
    userID: "user-b",
    customIDs: ["workID": "employee-b", "projectID": "project-b"],
    email: "user-b@statsig.io",
    ip: "5.6.7.8",
    country: "NZ",
    locale:"en_NZ",
    appVersion: "8.7.6",
    custom: ["hasPaid": true, "isVerified": false],
    privateAttributes: ["secret": "booo", "age": 29]
)

class UserHashingSpec: BaseSpec {
    override class func spec() {
        super.spec()

        describe("User Hashing") {

            it("gets the same has for identical users") {
                expect(userA.getFullUserHash()).to(equal(userAAgain.getFullUserHash()))
            }

            it("gets different hashes for different users") {
                expect(userA.getFullUserHash()).notTo(equal(userB.getFullUserHash()))
            }
        }
    }
}
