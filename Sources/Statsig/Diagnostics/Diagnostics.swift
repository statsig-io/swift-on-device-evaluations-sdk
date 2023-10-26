public protocol MarkersContainer {
    var overall: OverallMarker { get }
    var initialize: InitializeMarkers { get }
}

typealias MarkerAtomicDict = AtomicDictionary<[[String: Any]]>

public class Diagnostics {
    public static var instance: DiagnosticsImpl?
    internal static var sampling = Int.random(in: 1...10000)

    public static var mark: MarkersContainer? {
        get { return instance }
    }

    public static func boot(_ disabled: Bool?) {
        if disabled == true {
            return
        }

        if (sampling != 1) {
            return
        }

        instance = DiagnosticsImpl()
    }

    public static func shutdown() {
        instance = nil
    }
}

public class DiagnosticsImpl: MarkersContainer {
    public var overall: OverallMarker
    public var initialize: InitializeMarkers

    private var markers = MarkerAtomicDict(label: "com.Statsig.Diagnostics")

    fileprivate init() {
        self.overall = OverallMarker(markers)
        self.initialize = InitializeMarkers(markers)
    }

    public func getMarkers(forContext context: MarkerContext) -> [[String: Any]]? {
        return markers[context.rawValue]
    }

    public func clearMarkers(forContext context: MarkerContext) {
        markers[context.rawValue] = []
    }
}
