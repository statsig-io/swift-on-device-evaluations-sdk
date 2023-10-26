#import <XCTest/XCTest.h>

@import StatsigTestUtils;
@import StatsigOnDeviceEvaluations;
@import Nimble;
@import NimbleObjectiveC;

@interface StatsigClientTest : XCTestCase

@end

@implementation StatsigClientTest {
    StatsigOnDeviceEvaluationsClient *_client;
    StatsigUser *_user;
}

- (void)setUp {
    _client = [StatsigOnDeviceEvaluationsClient new];

    _user =
    [StatsigUser
     userWithUserID:@"a-user"];

    [NetworkStubs
     stubEndpoint:@"download_config_specs"
     withResource:@"RulesetsDownloadConfigsSpecs"
     times:1];

    waitUntil(^(void (^done)(void)){
        [_client
         initializeWithSDKKey:@"client-key"
         options:nil
         completion:^(NSError * _Nullable err) {
            done();
        }];
    });
}

- (void)testGetFeatureGate {
    FeatureGate *gate = [_client getFeatureGate:@"test_public" forUser:_user];
    expect(gate.value).to(beTrue());
}

@end
