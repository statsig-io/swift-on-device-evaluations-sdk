#import "PerfOnDeviceEvaluationsViewControllerObjC.h"
#import "StatsigSamples-Swift.h"

@import StatsigOnDeviceEvaluations;


static NSString * const CellIdentifier = @"Cell";

@interface PerfOnDeviceEvaluationsViewControllerObjC() <
UICollectionViewDataSource,
UICollectionViewDelegate,
StatsigListening
>

@end

@implementation PerfOnDeviceEvaluationsViewControllerObjC {
    UICollectionView *_collectionView;
    NSInteger _numCells;
    StatsigOnDeviceEvaluationsClient *_statsig;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupCollectionView];

    _statsig = [StatsigOnDeviceEvaluationsClient sharedInstance];

    StatsigOptions *opts = [StatsigOptions new];
    opts.maxEventQueueSize = 50;

    [_statsig
     initializeWithSDKKey:Constants.CLIENT_SDK_KEY
     options:opts
     completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error %@", error);
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self load];
        });
    }];

    [_statsig addListener:self];
}

- (void)load {
    _numCells = 9999;
    [_collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _numCells;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];

    NSString *userID =
    [NSString
     stringWithFormat:@"user-%ld", indexPath.item];

    StatsigUser *user =
    [StatsigUser
     userWithUserID:userID];

    BOOL gate = [_statsig checkGate:@"partial_gate" forUser:user];

    if (gate) {
        cell.backgroundColor = [UIColor systemGreenColor];
    } else {
        cell.backgroundColor = [UIColor systemRedColor];
    }

    return cell;
}

- (void)onStatsigClientEvent:(enum StatsigClientEvent)event
               withEventData:(NSDictionary<NSString *,id> * _Nonnull)eventData {
    if (event != StatsigClientEventEventsFlushed) {
        return;
    }

    NSArray *events = eventData[@"events"];
    if ([eventData[@"success"] isEqual:@true]) {
        NSLog(@"Events Flushed: %lu", [events count]);
    } else {
        NSLog(@"Failed to Flush Events: %lu", [events count]);
    }
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout =
    [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);

    _collectionView =
    [[UICollectionView alloc]
     initWithFrame:self.view.bounds
     collectionViewLayout:layout];

    _collectionView.dataSource = self;
    [_collectionView
     registerClass:[UICollectionViewCell class]
     forCellWithReuseIdentifier:CellIdentifier
    ];

    [self.view addSubview:_collectionView];
}

@end
