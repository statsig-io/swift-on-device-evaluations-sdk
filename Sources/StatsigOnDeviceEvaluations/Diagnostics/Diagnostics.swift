public protocol MarkersContainer {
    var overall: OverallMarker { get }
    var initialize: InitializeMarkers { get }
}

typealias MarkerAtomicDict = AtomicDictionary<[[String: Any]]>
typealias DiagnosticsMarker = [String: Any]

class Diagnostics {
    static var instance: DiagnosticsImpl?
    static var disabled = false

    static var mark: MarkersContainer? {
        get { return instance }
    }

    static func boot() {
        instance = DiagnosticsImpl()
    }

    static func shutdown() {
        instance = nil
    }

    static func log(_ logger: EventLogger, context: MarkerContext) {
        if disabled {
            return
        }

        guard
            let instance = instance,
            let markers = instance.getMarkers(forContext: context),
            !markers.isEmpty
        else {
            return
        }

        instance.clearMarkers(forContext: context)

        logger.enqueue { createDiagnosticsEvent(context, markers) }
    }

}

class DiagnosticsImpl: MarkersContainer {
    var overall: OverallMarker
    var initialize: InitializeMarkers

    private var markers = MarkerAtomicDict(label: "com.Statsig.OnDeviceEval.Diagnostics")

    fileprivate init() {
        self.overall = OverallMarker(markers)
        self.initialize = InitializeMarkers(markers)
    }

    func getMarkers(forContext context: MarkerContext) -> [DiagnosticsMarker]? {
        return markers[context.rawValue]
    }

    func clearMarkers(forContext context: MarkerContext) {
        markers[context.rawValue] = []
    }
}


internal func createDiagnosticsEvent(
    _ context: MarkerContext,
    _ markers: [DiagnosticsMarker]
) -> StatsigEventInternal {
    StatsigEventInternal(
        eventName: "statsig::diagnostics",
        value: nil,
        metadata: [
            "context" : context.rawValue,
            "markers" : markers
        ],
        user: .empty(),
        time: Time.now(),
        secondaryExposures: nil
    )
}
