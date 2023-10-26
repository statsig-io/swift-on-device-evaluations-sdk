import UIKit

import StatsigOnDeviceEvaluations

enum DemoType {
    case swiftOnDeviceBasic
    case swiftPrecompBasic
    case swiftSyncInit

    case objcOnDeviceBasic
    case objcOnDevicePerf
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        window = UIWindow()
        window?.rootViewController = getViewController(.swiftPrecompBasic)
        window?.makeKeyAndVisible()

        return true
    }

    private func getViewController(_ type: DemoType) -> UIViewController {
        switch type {
        case .swiftOnDeviceBasic:
            return BasicOnDeviceEvaluationsViewController()

        case .swiftPrecompBasic:
            return BasicPrecomputedEvaluationsViewController()

        case .swiftSyncInit:
            return SynchronousInitViewController()

        case .objcOnDeviceBasic:
            return BasicOnDeviceEvaluationsViewControllerObjC()

        case .objcOnDevicePerf:
            return PerfOnDeviceEvaluationsViewControllerObjC()
        }

    }
}

