#import <XCTest/XCTest.h>

#import "ObjcTestUtils.h"

@import StatsigPrecomputedEvaluations;

@interface ObjcStatsigUser : XCTestCase
@end

@implementation ObjcStatsigUser {
    StatsigUser *_userWithUserID;
    StatsigUser *_userWithCustomIDs;
}

- (void)setUp {
    _userWithUserID = [StatsigUser userWithUserID:@"a-user"];
    _userWithUserID.email = @"a-user@mail.com";
    _userWithUserID.ip = @"1.2.3.4";
    _userWithUserID.country = @"NZ";
    _userWithUserID.locale = @"en_NZ";
    _userWithUserID.appVersion = @"1.0.0";
    [_userWithUserID.custom setBoolean:true forKey:@"isEmployee"];
    [_userWithUserID.privateAttributes setString:@"secret_value" forKey:@"secret_key"];

    _userWithCustomIDs = [StatsigUser userWithCustomIDs:@{@"EmployeeID": @"Number1"}];
}

- (void)testGettingUserID {
    XCTAssertEqualObjects(_userWithUserID.userID, @"a-user");
    XCTAssertEqualObjects(_userWithCustomIDs.userID, @"");
}

- (void)testGettingCustomIDs {
    XCTAssertEqualObjects(_userWithUserID.customIDs, @{});
    XCTAssertEqualObjects(_userWithCustomIDs.customIDs, @{@"EmployeeID": @"Number1"});
}

- (void)testGettingAsDictionary {
    NSDictionary *dict = [_userWithUserID toDictionary];
    XCTAssertEqual([dict count], 10);
    XCTAssertEqual(dict[@"userID"], @"a-user");
    XCTAssertEqualObjects(dict[@"customIDs"], @{});
    XCTAssertEqual(dict[@"email"], @"a-user@mail.com");
    XCTAssertEqual(dict[@"ip"], @"1.2.3.4");
    XCTAssertEqual(dict[@"country"], @"NZ");
    XCTAssertEqual(dict[@"locale"], @"en_NZ");
    XCTAssertEqual(dict[@"appVersion"], @"1.0.0");
    XCTAssertEqualObjects(dict[@"custom"], @{@"isEmployee": @true});
    XCTAssertEqualObjects(dict[@"privateAttributes"], @{@"secret_key": @"secret_value"});
    XCTAssertEqualObjects(dict[@"statsigEnvironment"], @{});

    dict = [_userWithCustomIDs toDictionary];
    XCTAssertEqual([dict count], 3);
    XCTAssertEqualObjects(dict[@"userID"], @"");
    XCTAssertEqualObjects(dict[@"customIDs"], @{@"EmployeeID": @"Number1"});
    XCTAssertEqualObjects(dict[@"statsigEnvironment"], @{});
}

@end

