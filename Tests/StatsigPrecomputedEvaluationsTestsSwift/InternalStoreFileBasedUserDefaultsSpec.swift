import Foundation

import Nimble
import Quick
@testable import StatsigPrecomputedEvaluations


class InternalStoreFileBasedUserDefaultsSpec: InternalStoreSpec {
    override class func shouldResetUserDefaultsBeforeSuite() -> Bool {
        return false
    }

    override class func spec() {
        super.spec()

        beforeSuite {
            StatsigUserDefaults.defaults = FileBasedUserDefaults()
        }
        
        self.specImpl()
    }
}

