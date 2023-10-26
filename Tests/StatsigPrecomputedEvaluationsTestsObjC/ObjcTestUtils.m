#import "ObjcTestUtils.h"

#import <XCTest/XCTest.h>

@import OHHTTPStubs;

@implementation ObjcTestUtils

+ (XCTestExpectation *_Nonnull)stubNetwork {
    return [self stubNetworkCapturingLogs:^(NSArray *logs) {
        // noop
    }];
}

+ (XCTestExpectation *_Nonnull)stubNetworkCapturingLogs:(void (^_Nonnull)(NSArray * _Nonnull logs))onDidLog {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *resBundlePath = [bundle pathForResource:@"StatsigOnDeviceEvaluations_StatsigPrecomputedEvaluationsTestsObjC" ofType:@"bundle"];
    NSBundle *resBundle = [NSBundle bundleWithPath:resBundlePath];
    NSString *jsonPath = [resBundle pathForResource:@"initialize" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];

    XCTestExpectation *requestExpectation = [[XCTestExpectation alloc] initWithDescription: @"Network Request"];

    [HTTPStubs removeAllStubs];
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
      return [request.URL.host isEqualToString:@"api.statsig.com"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/v1/rgstr"]) {
            id dict = [NSJSONSerialization JSONObjectWithData:request.OHHTTPStubs_HTTPBody options:0 error:nil];
            onDidLog(dict[@"events"]);
        }

        [requestExpectation fulfill];
        return [HTTPStubsResponse
                responseWithData:data
                statusCode:200
                headers:@{@"Content-Type":@"application/json"}
        ];
    }];

    return requestExpectation;
}

@end
