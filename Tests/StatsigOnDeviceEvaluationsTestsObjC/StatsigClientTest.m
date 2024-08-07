#import <XCTest/XCTest.h>

@import StatsigTestUtils;
@import StatsigOnDeviceEvaluations;
@import Nimble;
@import NimbleObjectiveC;

@interface StatsigClientTest : XCTestCase

@end

@implementation StatsigClientTest {
    Statsig *_client;
    StatsigUser *_user;
    GetFeatureGateOptions *_options;
}

- (void)setUp {
    _client = [Statsig new];

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
    FeatureGate *gate = [_client getFeatureGate:@"test_public" forUser:_user options:_options];
    expect(gate.value).to(beTrue());
}

@end
