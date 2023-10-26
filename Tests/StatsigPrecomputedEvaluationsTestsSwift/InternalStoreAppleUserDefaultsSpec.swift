import Foundation

import Nimble
import Quick
@testable import StatsigPrecomputedEvaluations


class InternalStoreAppleUserDefaultsSpec: InternalStoreSpec {
    override class func spec() {
        super.spec()

        beforeSuite {
            StatsigUserDefaults.defaults = UserDefaults.standard
        }
        
        self.specImpl()
    }
}

