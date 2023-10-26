#import <XCTest/XCTest.h>

#import "ObjcTestUtils.h"

@import StatsigPrecomputedEvaluations;
@import OHHTTPStubs;
@import Nimble;
@import NimbleObjectiveC;

@interface ObjcManualExposureSpec : XCTestCase
@end

@implementation ObjcManualExposureSpec {
    XCTestExpectation *_requestExpectation;
    StatsigUser *_user;
    StatsigOptions *_options;
    void (^_completion)(NSString * _Nullable);
    NSArray *_logs;
}

- (void)setUp {
    _logs = [NSMutableArray array];
    _requestExpectation = [[XCTestExpectation alloc] initWithDescription: @"Network Request"];

    _requestExpectation = [ObjcTestUtils stubNetworkCapturingLogs:^(NSArray * _Nonnull logs) {
        _logs = [_logs arrayByAddingObjectsFromArray:logs];
    }];

    _user = [StatsigUser userWithUserID:@"a-user"];

    _options = [[StatsigOptions alloc] initWithArgs:@{@"initTimeout": @2}];
    _completion = ^(NSString * _Nullable err) {};
}

- (void)tearDown {
    [Statsig shutdown];
}

- (void)testManualGateExposure {
    [self initializeStatsig];

    FeatureGate *gate = [Statsig getFeatureGateWithExposureLoggingDisabled:@"test_public"];
    NSData *encoded = [gate toData];

    FeatureGate *decoded = [FeatureGate fromData:encoded];
    [Statsig manuallyLogExposureWithFeatureGate:decoded];

    [Statsig shutdown];

    expect(_logs.count).toEventually(equal(1));
    XCTAssertEqualObjects(_logs[0][@"eventName"], @"statsig::gate_exposure");
    XCTAssertEqualObjects(_logs[0][@"metadata"][@"gate"], @"test_public");
    XCTAssertEqualObjects(_logs[0][@"metadata"][@"isManualExposure"], @"true");
}

- (void)testManualConfigExposure {
    [self initializeStatsig];

    DynamicConfig *config = [Statsig getConfigWithExposureLoggingDisabled:@"test_disabled_config"];
    NSData *encoded = [config toData];

    DynamicConfig *decoded = [DynamicConfig fromData:encoded];
    [Statsig manuallyLogExposureWithDynamicConfig:decoded];

    [Statsig shutdown];

    expect(_logs.count).toEventually(equal(1));
    XCTAssertEqualObjects(_logs[0][@"eventName"], @"statsig::config_exposure");
    XCTAssertEqualObjects(_logs[0][@"metadata"][@"config"], @"test_disabled_config");
    XCTAssertEqualObjects(_logs[0][@"metadata"][@"isManualExposure"], @"true");
}

- (void)testManualLayerExposure {
    [self initializeStatsig];

    Layer *layer = [Statsig getLayerWithExposureLoggingDisabled:@"layer_with_many_params"];
    NSData *encoded = [layer toData];

    Layer *decoded = [Layer fromData:encoded];
    [Statsig manuallyLogExposureWithLayer:decoded parameterName:@"a_string"];

    [Statsig shutdown];

    expect(_logs.count).toEventually(equal(1));
    XCTAssertEqualObjects(_logs[0][@"eventName"], @"statsig::layer_exposure");
    XCTAssertEqualObjects(_logs[0][@"metadata"][@"config"], @"layer_with_many_params");
    XCTAssertEqualObjects(_logs[0][@"metadata"][@"parameterName"], @"a_string");
    XCTAssertEqualObjects(_logs[0][@"metadata"][@"isManualExposure"], @"true");
}

#pragma mark - Helpers

- (void)initializeStatsig
{
    [Statsig startWithSDKKey:@"client-"];
    [self waitForExpectations:@[_requestExpectation] timeout:1];
}

@end

