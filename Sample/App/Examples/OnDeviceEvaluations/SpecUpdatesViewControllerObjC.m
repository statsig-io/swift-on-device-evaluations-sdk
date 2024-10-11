#import "SpecUpdatesViewControllerObjC.h"
#import "StatsigSamples-Swift.h"
#import <dispatch/dispatch.h>

@interface SpecUpdatesViewControllerObjC() <StatsigListening> {
    Statsig *_client;
    StatsigUpdatesHandle *_handle;
}

@end

@implementation SpecUpdatesViewControllerObjC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _client = [[Statsig alloc] init];
    
    [_client addListener:self];
    
    [_client
     initializeWithSDKKey:Constants.CLIENT_SDK_KEY
     options:nil
     completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error %@", error);
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addButtonWithTitle:@"Update Now" action:@selector(onUpdateNowTouchUpInside) yPosition:100];
            [self addButtonWithTitle:@"Schedule Background Updates" action:@selector(onScheduleUpdatesTouchUpInside) yPosition:200];
            [self addButtonWithTitle:@"Stop Background Updates" action:@selector(onStopUpdatesTouchUpInside) yPosition:300];
        });
    }];
}

- (void)addButtonWithTitle:(NSString *)title action:(SEL)action yPosition:(CGFloat)yPosition {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    // Set the button's size to fit its content
    [button sizeToFit];
    
    CGRect frame = button.frame;
    frame.size.width += 40; // Add some padding
    frame.size.height = 50; // Set a fixed height
    
    // Center the button horizontally
    frame.origin.x = (self.view.bounds.size.width - frame.size.width) / 2;
    frame.origin.y = yPosition;
    
    button.frame = frame;
    [self.view addSubview:button];
}

- (void)onUpdateNowTouchUpInside {
    NSLog(@"onUpdateNowTouchUpInside");
    
    [_client updateWithCompletion:^(NSError *_Nullable error) {
        if (error == nil) {
            NSLog(@"Update Completed Successfully");
        } else {
            NSLog(@"Update Errored: %@", error);
        }
    }];
}

- (void)onScheduleUpdatesTouchUpInside {
    NSLog(@"onScheduleUpdatesTouchUpInside");
    _handle = [_client scheduleBackgroundUpdatesWithIntervalSeconds:10];
}

- (void)onStopUpdatesTouchUpInside {
    NSLog(@"onStopUpdatesTouchUpInside");
    [_handle cancel];
}

- (void)onStatsigClientEvent:(enum StatsigClientEvent)event 
               withEventData:(NSDictionary<NSString *,id> * _Nonnull)eventData {
    NSLog(@"StatsigClientEvent %ld - %@", (long)event, eventData);
}

@end
