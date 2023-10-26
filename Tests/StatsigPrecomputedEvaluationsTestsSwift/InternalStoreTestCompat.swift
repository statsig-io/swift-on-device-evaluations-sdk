@testable import StatsigPrecomputedEvaluations

extension InternalStore {
    convenience init(_ user: StatsigUser) {
        self.init(user, options: StatsigOptions())
    }
}
