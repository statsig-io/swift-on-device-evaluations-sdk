#import "ClientEventsViewControllerObjC.h"
#import "StatsigSamples-Swift.h"

@interface ClientEventsViewControllerObjC() <StatsigListening>

@end

@implementation ClientEventsViewControllerObjC

- (void)viewDidLoad {
    [super viewDidLoad];

    [[Statsig sharedInstance] addListener:self];

    __weak ClientEventsViewControllerObjC *weakSelf = self;
    [[Statsig sharedInstance]
     initializeWithSDKKey:Constants.CLIENT_SDK_KEY
     options:nil
     completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf onInitialized:error];
        });
    }];
}

- (void)onInitialized:(NSError *)error {
    if (error != nil) {
        NSLog(@"Error %@", error);
        return;
    }

    StatsigUser *user =
    [StatsigUser
     userWithUserID:@"a-user"];

    FeatureGate *gate =
    [[Statsig sharedInstance]
     getFeatureGate:@"a_gate"
     forUser:user];

    NSLog(@"Result: %@", gate.value ? @"Pass" : @"Fail");
    NSLog(@"Details: %@", gate.evaluationDetails.reason);
}

- (void)onStatsigClientEvent:(enum StatsigClientEvent)event withEventData:(NSDictionary<NSString *,id> * _Nonnull)eventData {
    NSLog(@"Event %ld - %@", (long)event, eventData);
}


@end
