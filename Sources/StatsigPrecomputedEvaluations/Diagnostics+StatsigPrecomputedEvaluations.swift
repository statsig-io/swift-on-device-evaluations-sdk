import StatsigInternal


extension Diagnostics {
    static func log(
        _ logger: EventLogger,
        user: StatsigUser,
        context: MarkerContext
    ) {
        guard
            let instance = instance,
            let markers = instance.getMarkers(forContext: context),
            !markers.isEmpty
        else {
            return
        }

        instance.clearMarkers(forContext: context)

        let event = DiagnosticsEvent(user, context.rawValue, markers)
        logger.log(event)
    }
}
