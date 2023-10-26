#import "BasicOnDeviceEvaluationsViewControllerObjC.h"
#import "StatsigSamples-Swift.h"

@import Statsig;

@implementation BasicOnDeviceEvaluationsViewControllerObjC

- (void)viewDidLoad {
    [super viewDidLoad];

    StatsigUser *user =
    [StatsigUser
     userWithUserID:@"a-user"];

    StatsigUserValueMap *custom = [StatsigUserValueMap new];
    [custom setString:@"jkw" forKey:@"name"];
    [custom setDouble:1.2 forKey:@"speed"];
    [custom setBoolean:true forKey:@"verified"];
    [custom setInteger:3 forKey:@"visits"];
    [custom setStrings:@[@"cool", @"rad", @"neat"] forKey:@"tags"];
    user.custom = custom;

    StatsigOnDeviceEvaluationsClient *client = [StatsigOnDeviceEvaluationsClient sharedInstance];

    [client
     initializeWithSDKKey:Constants.CLIENT_SDK_KEY
     options:nil
     completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error %@", error);
            return;
        }

        FeatureGate *gate =
        [client
         getFeatureGate:@"a_gate"
         forUser:user];

        NSLog(@"Result: %@", gate ? @"Pass" : @"Fail");
        NSLog(@"Details: %@", gate.evaluationDetails.reason);
    }];

    [client
     logEvent:
         [StatsigEvent
          eventWithName:@"statsig_init_start"
          stringValue:nil
          metadata:nil]
     forUser:user];

    [client
     logEvent:
         [StatsigEvent
          eventWithName:@"statsig_init_time"
          doubleValue:[[NSDate now] timeIntervalSince1970] * 1000
          metadata:nil]
     forUser:user];
}

@end
