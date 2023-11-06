#import <XCTest/XCTest.h>

@import StatsigTestUtils;
@import StatsigOnDeviceEvaluations;
@import Nimble;
@import NimbleObjectiveC;

@interface StatsigUserTest : XCTestCase
@end

@implementation StatsigUserTest {
    StatsigUser *_user;
}

- (void)setUp {
    _user =
    [StatsigUser
     userWithUserID:@"a-user"];

    _user.email = @"a@user.mail";
    _user.ip = @"1.2.3.4";
    _user.userAgent = @"Mozilla/5.0";
    _user.country = @"NZ";
    _user.locale = @"en_US";
    _user.appVersion = @"4.20.0";

//    [_user.custom setString:@"jkw" forKey:@"name"];
//    [_user.custom setDouble:1.2 forKey:@"speed"];
//    [_user.custom setStrings:@[@"cool", @"rad", @"neat"] forKey:@"tags"];
//
//    [_user.privateAttributes setString:@"jkw" forKey:@"name"];
//    [_user.privateAttributes setInteger:42 forKey:@"level"];
//    [_user.privateAttributes setBoolean:true forKey:@"verified"];
}

- (void)testUserValues {
    expect(_user.userID).to(equal("a-user"));
    expect(_user.email).to(equal("a@user.mail"));
    expect(_user.ip).to(equal("1.2.3.4"));
    expect(_user.country).to(equal("NZ"));
    expect(_user.locale).to(equal("en_US"));
}

@end
