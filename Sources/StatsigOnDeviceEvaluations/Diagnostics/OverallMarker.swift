public class OverallMarker: MarkerBase {
    convenience init(_ recorder: MarkerAtomicDict) {
        self.init(recorder, context: .initialize, markerKey: "overall")
    }

    public func start() {
        super.start([:])
    }

    public func end(success: Bool, details: [String: Any], errorMessage: String?) {
        var args: [String: Any] = [
            "success": success,
            "evaluationDetails": details
        ]

        if let message = errorMessage {
            args["error"] = [
                "name": "Error",
                "message": message
            ]
        }

        super.end(args)
    }
}
