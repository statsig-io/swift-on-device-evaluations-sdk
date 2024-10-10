import Foundation

fileprivate let STORE_LABEL = "com.statsig.spec_store"

typealias SpecAndSourceInfo = (spec: Spec?, sourceInfo: SpecStoreSourceInfo)

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
    private let queue = DispatchQueue(label: STORE_LABEL, attributes: .concurrent)
    private let emitter: StatsigClientEventEmitter

    private var sourceInfo = SpecStoreSourceInfo(
        source: .uninitialized,
        receivedAt: 0,
        lcut: 0
    )
    private var specs: [SpecType: [String: Spec]] = [:]

    init(_ emitter: StatsigClientEventEmitter) {
        self.emitter = emitter
        specs = [:]
    }

    public func setAndCacheValues(
        response: SpecsResponseFull,
        responseData: Data,
        sdkKey: String,
        source: ValueSource
    ) {
        setValues(response, responseData: responseData, source: source)
        FileUtil.writeToCache(sdkKey.djb2(), responseData)
    }

    func getSpecAndSourceInfo(
        _ type: SpecType,
        _ name: String
    ) -> SpecAndSourceInfo {
        queue.sync {(
            specs[type]?[name],
            self.sourceInfo
        )}
    }

    func getSourceInfo() -> SpecStoreSourceInfo {
        queue.sync { self.sourceInfo }
    }

    func loadFromCache(_ sdkKey: String) {
        guard let data = FileUtil.readFromCache(sdkKey.djb2()) else {
            return
        }

        do {
            let decoded = try JSONDecoder()
                .decode(SpecsResponse.self, from: data)
            
            guard case .full(let decoded) = decoded else {
                return
            }
            
            setValues(decoded, responseData: data, source: .cache)
        } catch {
            return
        }
    }

    private func setValues(_ response: SpecsResponseFull, responseData: Data, source: ValueSource) {
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

            self.emitter.emit(.valuesUpdated, [
                "data": responseData,
                "source": source.rawValue
            ])
        }
    }
}

