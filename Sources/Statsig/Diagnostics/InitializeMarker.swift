public class InitializeMarkers {
    public let network: NetworkMarker
    public let process: ProcessMarker
    
    let key = "initialize"

    init(_ recorder: MarkerAtomicDict) {
        self.network = NetworkMarker(recorder, key: key)
        self.process = ProcessMarker(recorder, key: key)
    }
}
