#import <XCTest/XCTest.h>

@import StatsigTestUtils;
@import StatsigOnDeviceEvaluations;
@import Nimble;
@import NimbleObjectiveC;

@interface StatsigSharedTest : XCTestCase

@end

@implementation StatsigSharedTest {
    StatsigUser *_user;
}

- (void)setUp {
    _user =
    [StatsigUser
     userWithUserID:@"a-user"];

    [NetworkStubs
     stubEndpoint:@"download_config_specs"
     withResource:@"RulesetsDownloadConfigsSpecs"
     times:1];

    waitUntil(^(void (^done)(void)){
        [[Statsig sharedInstance]
         initializeWithSDKKey:@"client-key"
         options:nil
         completion:^(NSError * _Nullable err) {
            done();
        }];
    });
}

- (void)testGetFeatureGate {
    FeatureGate *gate =
    [[Statsig sharedInstance]
     getFeatureGate:@"test_public" forUser:_user];
    expect(gate.value).to(beTrue());
}

@end
