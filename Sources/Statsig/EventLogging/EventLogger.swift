import Foundation

fileprivate let LOGGER_LABEL = "com.statsig.event_logger"

class EventLogger {

    var options: StatsigOptions?

    private let queue = DispatchQueue(label: LOGGER_LABEL)
    private let network: NetworkService
    private let emitter: StatsigClientEventEmitter

    private var events: [StatsigEventInternal] = []

    init(_ network: NetworkService,
         _ emitter: StatsigClientEventEmitter) {
        self.network = network
        self.emitter = emitter
    }

    func enqueue(_ eventFactory: @escaping () -> StatsigEventInternal) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.enqueueImpl(eventFactory)
        }
    }

    func flush() {
        let pending = queue.sync {
            let result = events
            events = []
            return result
        }

        if (pending.isEmpty) {
            return
        }

        network.post(
            .logEvent,
            payload: [
                "events": pending.map { $0.toLoggable() },
                //                "statsigMetadata": forUser.deviceEnvironment
            ],
            retries: 3
        ) { [weak emitter] (data: LogEventResponse?, error) in
            emitter?.emit(.eventsFlushed, [
                "events": pending,
                "success": error == nil && data?.success == true
            ])
        }
    }

    private func enqueueImpl(_ eventFactory: () -> StatsigEventInternal) {
        let event = eventFactory()
        let shouldFlush = queue.sync {
            events.append(event)
            let max = options?.maxEventQueueSize ?? StatsigOptions.Defaults.maxEventQueueSize
            return events.count >= max
        }

        if (shouldFlush) {
            flush()
        }
    }
}
