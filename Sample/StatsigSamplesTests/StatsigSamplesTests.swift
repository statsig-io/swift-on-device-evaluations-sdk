import XCTest

@testable import StatsigSamples

final class StatsigSamplesTests: XCTestCase {

    func testExampleViewControllersCompile() throws {
        let controllers: [UIViewController] = [
            BasicOnDeviceEvaluationsViewController(),
            SynchronousInitViewController(),
            ClientEventsViewController(),
            BasicOnDeviceEvaluationsViewControllerObjC(),
            PerfOnDeviceEvaluationsViewControllerObjC()
        ]

        XCTAssertNotNil(controllers)
    }

}
