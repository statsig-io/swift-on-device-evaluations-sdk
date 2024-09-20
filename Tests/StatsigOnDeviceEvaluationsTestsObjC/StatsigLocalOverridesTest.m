#import <XCTest/XCTest.h>

@import StatsigTestUtils;
@import StatsigOnDeviceEvaluations;
@import Nimble;
@import NimbleObjectiveC;

@interface StatsigLocalOverridesTest : XCTestCase

@end

@implementation StatsigLocalOverridesTest {
    Statsig *_client;
    LocalOverrideAdapter *_overrides;
    StatsigUser *_user;
}

- (void)setUp {
    _client = [Statsig new];
    
    _user =
    [StatsigUser
     userWithCustomIDs:@{@"employeeID": @"an_employee"}];
    
    [NetworkStubs
     stubEndpoint:@"download_config_specs"
     withResource:@"RulesetsDownloadConfigsSpecs"
     times:1];
    
    _overrides = [[LocalOverrideAdapter alloc] initWithIdType:@"employeeID"];
    
    StatsigOptions *opts = [StatsigOptions new];
    opts.overrideAdapter = _overrides;
    
    waitUntil(^(void (^done)(void)) {
        [_client
         initializeWithSDKKey:@"client-key"
         options:opts
         completion:^(NSError * _Nullable err) {
            done();
        }];
    });
}

- (void)testGateOverrides {
    NSString *gateName = @"local_override_gate";
    
    [_overrides
     setGateForUser:_user
     name:gateName
     gate:[FeatureGate
           createWithName:gateName
           andValue:true]];
    
    FeatureGate *gate = [_client getFeatureGate:gateName forUser:_user options:nil];
    expect(gate.value).to(beTrue());
    expect(gate.evaluationDetails.reason).to(equal(@"LocalOverride"));
    
    [_overrides removeGateForUser:_user name:gateName];
    gate = [_client getFeatureGate:gateName forUser:_user options:nil];
    expect(gate.value).to(beFalse());
    expect(gate.evaluationDetails.reason).to(equal(@"Unrecognized"));
}

- (void)testDynamicConfigOverrides {
    NSString *configName = @"local_override_config";
    
    [_overrides
     setConfigForUser:_user
     name:configName
     config:[DynamicConfig
             createWithName:configName
             andValue:@{@"foo": @"bar"}]];
    
    DynamicConfig *config = [_client getDynamicConfig:configName forUser:_user options:nil];
    expect(config.value[@"foo"]).to(equal(@"bar"));
    expect(config.evaluationDetails.reason).to(equal(@"LocalOverride"));
    
    [_overrides removeDynamicConfigForUser:_user name:configName];
    config = [_client getDynamicConfig:configName forUser:_user options:nil];
    expect(config.value).to(equal(@{}));
    expect(config.evaluationDetails.reason).to(equal(@"Unrecognized"));
}

- (void)testExperimentOverrides {
    NSString *experimentName = @"local_override_experiment";
    
    [_overrides
     setExperimentForUser:_user
     name:experimentName
     experiment:[Experiment
                 createWithName:experimentName
                 andValue:@{@"foo": @"bar"}]];
    
    Experiment *experiment = [_client getExperiment:experimentName forUser:_user options:nil];
    expect(experiment.value[@"foo"]).to(equal(@"bar"));
    expect(experiment.evaluationDetails.reason).to(equal(@"LocalOverride"));
    
    [_overrides removeExperimentForUser:_user name:experimentName];
    experiment = [_client getExperiment:experimentName forUser:_user options:nil];
    expect(experiment.value).to(equal(@{}));
    expect(experiment.evaluationDetails.reason).to(equal(@"Unrecognized"));
}

- (void)testLayerOverrides {
    NSString *layerName = @"local_override_layer";
    
    [_overrides
     setLayer:_user
     name:layerName
     layer:[Layer createWithName:layerName andValue:@{@"foo": @"bar"}]];
    
    Layer *layer = [_client getLayer:layerName forUser:_user options:nil];
    expect(layer.value[@"foo"]).to(equal(@"bar"));
    expect(layer.evaluationDetails.reason).to(equal(@"LocalOverride"));
    
    [_overrides removeLayerForUser:_user name:layerName];
    layer = [_client getLayer:layerName forUser:_user options:nil];
    expect(layer.value).to(equal(@{}));
    expect(layer.evaluationDetails.reason).to(equal(@"Unrecognized"));
}

- (void)testDifferingIdTypes {
    NSString *gateName = @"local_override_gate";
    
    StatsigUser *otherUser = [StatsigUser userWithCustomIDs:@{@"employeeID": @"another_employee"}];
    
    [_overrides
     setGateForUser:otherUser
     name:gateName
     gate:[FeatureGate
           createWithName:gateName
           andValue:true]];
    
    FeatureGate *gate = [_client getFeatureGate:gateName forUser:otherUser options:nil];
    expect(gate.value).to(beTrue());
    expect(gate.evaluationDetails.reason).to(equal(@"LocalOverride"));
    
    gate = [_client getFeatureGate:gateName forUser:_user options:nil];
    expect(gate.value).to(beFalse());
    expect(gate.evaluationDetails.reason).to(equal(@"Unrecognized"));
}

@end
