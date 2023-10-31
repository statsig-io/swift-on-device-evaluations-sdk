import Foundation

fileprivate let STORE_LABEL = "com.statsig.spec_store"

enum SpecType {
    case gate
    case config
    case layer
}

enum ValueSource: String {
    case network = "Network"
    case cache = "Cache"
    case bootstrap = "Bootstrap"
    case uninitialized = "Uninitialized"
}

struct SpecStoreSourceInfo {
    let source: ValueSource
    let receivedAt: Int64
    let lcut: Int64
}

class SpecStore {
    public private(set) var sourceInfo = SpecStoreSourceInfo(
        source: .uninitialized,
        receivedAt: 0,
        lcut: 0
    )

    private let queue = DispatchQueue(label: STORE_LABEL, attributes: .concurrent)

    private var specs: [SpecType: [String: Spec]] = [:]

    init() {
        specs = [:]
    }

    func setValues(_ response: DownloadConfigSpecsResponse, source: ValueSource) {
        let newSpecs = [
            (SpecType.gate, response.featureGates),
            (SpecType.config, response.dynamicConfigs),
            (SpecType.layer, response.layerConfigs)
        ].reduce(into: [SpecType: [String: Spec]]()) { acc, curr in
            let (type, specs) = curr
            var result = [String: Spec]()
            for spec in specs {
                result[spec.name] = spec
            }
            acc[type] = result
        }

        queue.async(flags: .barrier) {
            self.sourceInfo = SpecStoreSourceInfo(
                source: source,
                receivedAt: Time.now(),
                lcut: response.time
            )
            self.specs = newSpecs
        }
    }

    func getSpecAndSourceInfo(_ type: SpecType, _ name: String) -> (spec: Spec?, sourceInfo: SpecStoreSourceInfo) {
        queue.sync {(
            specs[type]?[name],
            self.sourceInfo
        )}
    }

    func getSourceInfo() -> SpecStoreSourceInfo {
        queue.sync { self.sourceInfo }
    }
}

