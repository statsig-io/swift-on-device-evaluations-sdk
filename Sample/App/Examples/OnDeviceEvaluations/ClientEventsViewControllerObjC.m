#import "ClientEventsViewControllerObjC.h"
#import "StatsigSamples-Swift.h"

const BOOL SHOULD_DEMO_ERROR_EVENTS = false;

@interface ClientEventsViewControllerObjC() <StatsigListening, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *receivedEvents;

@end

@implementation ClientEventsViewControllerObjC

- (void)viewDidLoad {
    [super viewDidLoad];

    _receivedEvents = [NSMutableArray array];

    [self setupTableView];
    [self setupNavbar];

    [[Statsig sharedInstance] addListener:self];

    if (SHOULD_DEMO_ERROR_EVENTS) {
        BOOL res __unused =
        [[Statsig sharedInstance]
         checkGate:@"a_gate" forUser:nil]; // Fires "Uninitialized" error
    }

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

- (void)onStatsigClientEvent:(enum StatsigClientEvent)event
               withEventData:(NSDictionary<NSString *,id> * _Nonnull)eventData {
    NSLog(@"Event %ld - %@", (long)event, eventData);

    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    for (NSString *key in eventData) {
        id value = eventData[key];

        if ([value isKindOfClass:[NSString class]]) {
            data[key] = (NSString *)value;
        } else if ([value isKindOfClass:[NSData class]]) {
            data[key] = [[NSString alloc] initWithData:(NSData *)value encoding:NSUTF8StringEncoding];
        } else {
            data[key] = [NSString stringWithFormat:@"%@", value];
        }
    }

    long long now = [[NSDate date] timeIntervalSince1970] * 1000;

    [self.receivedEvents
     addObject:@{
        @"time": @(now),
        @"event": [self stringFromEvent: event],
        @"data": data
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)setupNavbar {
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc]
     initWithTitle:@"Log Event"
     style:UIBarButtonItemStylePlain
     target:self
     action:@selector(logEventTapped)];
}


- (void)logEventTapped {
    StatsigUser *user = [StatsigUser userWithUserID:@"a-user"];
    StatsigEvent *event = [StatsigEvent eventWithName:@"my_custom_event"];

    [[Statsig sharedInstance] logEvent:event forUser:user];
}

- (NSString *)stringFromEvent:(enum StatsigClientEvent)event {
    switch (event) {
        case StatsigClientEventValuesUpdated:
            return @"ValuesUpdated";
        case StatsigClientEventEventsFlushed:
            return @"EventsFlushed";
        case StatsigClientEventError:
            return @"Error";
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.receivedEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }

    NSDictionary *eventInfo = self.receivedEvents[indexPath.item];
    NSNumber *time = eventInfo[@"time"];

    NSDictionary *data = eventInfo[@"data"];

    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", time, eventInfo[@"event"]];

    NSArray *formatted = [data.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableString *detailText = [NSMutableString new];
    for (NSString *key in formatted) {
        NSString *result = [NSString stringWithFormat:@"%@: %@", key, data[key]];
        [detailText appendFormat:@"%@\n", [result substringToIndex:MIN(result.length, 200)]];
    }

    cell.detailTextLabel.text = detailText;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

    return cell;
}

@end
