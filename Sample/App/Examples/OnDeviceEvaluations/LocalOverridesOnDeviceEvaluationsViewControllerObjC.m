#import "LocalOverridesOnDeviceEvaluationsViewControllerObjC.h"
#import "StatsigSamples-Swift.h"

@import StatsigOnDeviceEvaluations;

@implementation LocalOverridesOnDeviceEvaluationsViewControllerObjC

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

    Statsig *client = [Statsig sharedInstance];

    LocalOverrideAdapter *overrides = [LocalOverrideAdapter new];
    [overrides 
     setGateForUser:user
     name:@"local_override_gate" 
     gate:[FeatureGate createWithName:@"local_override_gate" andValue:true]];
    
    StatsigOptions *options = [StatsigOptions new];
    options.overrideAdapter = overrides;

    [client
     initializeWithSDKKey:Constants.CLIENT_SDK_KEY
     options:options
     completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error %@", error);
            return;
        }

        FeatureGate *gate =
        [client
         getFeatureGate:@"local_override_gate"
         forUser:user
         options: nil];

        NSLog(@"Result: %@", gate.value ? @"Pass" : @"Fail");
        NSLog(@"Details: %@", gate.evaluationDetails.reason);

        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.backgroundColor = gate.value == true ? UIColor.systemGreenColor : UIColor.systemRedColor;
        });
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
