import Quick
import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import StatsigOnDeviceEvaluations

final class SpecTest: QuickSpec {
    override class func spec() {
        describe("Spec") {
            var spec: Spec!
            var rule: SpecRule!
            var condition: SpecCondition!

            beforeSuite {
                let data = json.data(using: .utf8)!
                spec = try! JSONDecoder().decode(Spec.self, from: data)
                rule = spec.rules[0]
                condition = spec.rules[0].conditions[0]
            }

            it("converts a spec") {
                expect(spec.name).to(equal("a_spec_name"))
                expect(spec.type).to(equal("feature_gate"))
                expect(spec.salt).to(equal("some-spec-salt-value"))
                expect(spec.defaultValue).to(equal(.bool(false)))
                expect(spec.enabled).to(beTrue())
                expect(spec.idType).to(equal("userID"))
                expect(spec.rules).to(haveCount(1))
            }

            it("parses the rule") {
                expect(rule.name).to(equal("a_rule_name"))
                expect(rule.passPercentage).to(equal(100))
                expect(rule.conditions).to(haveCount(1))
                expect(rule.returnValue).to(equal(.bool(true)))
                expect(rule.id).to(equal("a_rule_id"))
                expect(rule.salt).to(equal("some-rule-salt-value"))
                expect(rule.idType).to(equal("userID"))
                expect(rule.configDelegate).to(equal("a_config_delegate"))
                expect(rule.isExperimentGroup).to(equal(false))
                expect(rule.groupName).to(equal("a_group_name"))
            }

            it("parses the condition") {
                expect(condition.type).to(equal("a_condition_type"))
                expect(condition.targetValue?.asString())
                    .to(equal("1.3"))
                expect(condition.operator).to(equal("an_operator"))
                expect(condition.field).to(equal("isEmployee"))
                expect(condition.additionalValues)
                    .to(equal(["salt":.string("some-condition-salt-value")]))
                expect(condition.idType).to(equal("userID"))
            }
        }
    }
}

fileprivate let json = """
{
    "name": "a_spec_name",
    "type": "feature_gate",
    "salt": "some-spec-salt-value",
    "enabled": true,
    "defaultValue": false,
    "rules": [
        {
            "name": "a_rule_name",
            "passPercentage": 100,
            "conditions": [
                {
                    "type": "a_condition_type",
                    "targetValue": "1.3",
                    "operator": "an_operator",
                    "field": "isEmployee",
                    "additionalValues": {
                        "salt": "some-condition-salt-value"
                    },
                    "isDeviceBased": false,
                    "idType": "userID"
                }
            ],
            "returnValue": true,
            "id": "a_rule_id",
            "salt": "some-rule-salt-value",
            "isDeviceBased": false,
            "idType": "userID",
            "configDelegate": "a_config_delegate",
            "isExperimentGroup": false,
            "groupName": "a_group_name"
        }
    ],
    "isDeviceBased": false,
    "idType": "userID",
    "entity": "feature_gate"
}
"""
