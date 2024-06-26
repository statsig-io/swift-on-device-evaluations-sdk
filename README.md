# StatsigOnDeviceEvaluations

A version of the Statsig iOS SDK that operates on the rule definitions to evaluate any gate/experiment locally (more like a Statsig server SDK).  This means when you change the user object or set of properties to check against, you do not need to make a network request to statsig - the SDK already has everything it needs to evaluate an arbitrary user object against an experiment or feature gate.  You can choose to host the rulesets for your project on your own CDN, or bundle them with your Application.  

Statsig helps you move faster with feature gates (feature flags), and/or dynamic configs. It also allows you to run A/B/n tests to validate your new features and understand their impact on your KPIs. If you're new to Statsig, check out our product and create an account at [statsig.com](https://www.statsig.com).

## Getting Started
Check out our [SDK docs](https://docs.statsig.com/client/swiftOnDeviceEvaluationSDK) to get started.

## Supported Features
- Gate Checks
- Dynamic Configs
- Layers/Experiments
- Custom Event Logging
- Synchronous and Asynchronous initialization

## Unsupported Features - relative to [Statsig iOS](https://github.com/statsig-io/ios-sdk)
- Local Overrides
- Big ID List based segments (>1k IDs)
- IP/UA Based Checks, inferred country from IP

## Apple's Privacy Manifest

Following Apple's rules, we've included a Privacy Manifest in the StatsigOnDeviceEvaluations SDK to explain its basic features. 
Developers will need to fill out their own Privacy Manifest, listing the information they add to the StatsigUser class. 
Important details like UserID and Email should be mentioned, but they aren't included by default because not everyone using the SDK will include these details in their StatsigUser class.

For more on how we use and handle data in our SDK, look at the PrivacyInfo.xcprivacy file. If you need help putting these steps into action in your app, check Apple's official guide on Privacy Manifests at https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_data_use_in_privacy_manifests.
