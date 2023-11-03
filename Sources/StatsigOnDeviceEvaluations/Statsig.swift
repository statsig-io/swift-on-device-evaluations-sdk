import Foundation

public typealias InitCompletion = (_ error: Error?) -> Void
public typealias ShutdownCompletion = (_ error: Error?) -> Void

@objc
public protocol SynchronousSpecsValue {}

extension NSData: SynchronousSpecsValue {}
extension NSString: SynchronousSpecsValue {}

public final class Statsig: NSObject {
    var options: StatsigOptions?

    let store: SpecStore
    let evaluator: Evaluator
    let network: NetworkService
    let logger: EventLogger
    let emitter: StatsigClientEventEmitter

    @objc(sharedInstance)
    public static var shared: Statsig = {
        return Statsig()
    }()

    @objc public override init() {
        emitter = StatsigClientEventEmitter()
        store = SpecStore()
        evaluator = Evaluator(store)
        network = NetworkService()
        logger = EventLogger(network, emitter)
        super.init()
    }

    @objc(initializeWithSDKKey:options:completion:)
    public func initialize(
        _ sdkKey: String,
        options: StatsigOptions? = nil,
        completion: InitCompletion? = nil
    ) {
        let endDiagnostics = trackInitDiagnostics()

        self.network.setRequiredFields(sdkKey, options)
        self.logger.options = options
        self.options = options
        self.store.loadFromCache(sdkKey)

        setValuesFromNetwork(sdkKey) { error in
            endDiagnostics(error)
            completion?(error)
        }
    }

    @objc(initializeSyncWithSDKKey:initialSpecs:options:)
    public func initializeSync(
        _ sdkKey: String,
        initialSpecs: SynchronousSpecsValue,
        options: StatsigOptions? = nil
    ) -> Error? {
        let endDiagnostics = trackInitDiagnostics()

        self.network.setRequiredFields(sdkKey, options)
        self.logger.options = options
        self.options = options

        let error = setValuesFromInitialSpecs(sdkKey, initialSpecs)
        endDiagnostics(error)
        return error
    }

    @objc
    public func shutdown(completion: ShutdownCompletion? = nil) {
        self.logger.shutdown { err in completion?(err) }
    }

    @objc(logEvent:forUser:)
    public func logEvent(
        _ event: StatsigEvent,
        _ user: StatsigUser
    ) {
        let userInternal = internalizeUser(user, options)

        logger.enqueue { event.toInternal(userInternal, nil) }
    }

    @objc
    public func flushEvents() {
        logger.flush()
    }

    @objc
    public func addListener(_ listener: StatsigListening) {
        emitter.addListener(listener)
    }

    @objc
    public func removeListener(_ listener: StatsigListening) {
        emitter.removeListener(listener)
    }
}


// MARK: Check APIs
extension Statsig {
    @objc(checkGate:forUser:)
    public func checkGate(_ name: String, _ user: StatsigUser) -> Bool {
        return getFeatureGate(name, user).value
    }

    @objc(getFeatureGate:forUser:)
    public func getFeatureGate(_ name: String, _ user: StatsigUser) -> FeatureGate {
        let userInternal = internalizeUser(user, options)
        let (evaluation, details) = evaluator.checkGate(name, userInternal)

        logger.enqueue{
            createGateExposure(
                user: userInternal,
                gateName: name,
                evaluation: evaluation,
                details: details
            )
        }

        return FeatureGate(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.boolValue
        )
    }

    @objc(getDynamicConfig:forUser:)
    public func getDynamicConfig(_ name: String, _ user: StatsigUser) -> DynamicConfig {
        let (evaluation, details) = getConfigImpl(name, user)

        return DynamicConfig(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }

    @objc(getExperiment:forUser:)
    public func getExperiment(_ name: String, _ user: StatsigUser) -> Experiment {
        let (evaluation, details) = getConfigImpl(name, user)

        return Experiment(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }

    @objc(getLayer:forUser:)
    public func getLayer(_ name: String, _ user: StatsigUser) -> Layer {
        let userInternal = internalizeUser(user, options)
        let (evaluation, details) = evaluator.getLayer(name, userInternal)

        let logExposure: ParameterExposureFunc = { [weak self] layer, parameter in
            let exposure = createLayerExposure(
                user: userInternal,
                layerName: name,
                parameter: parameter,
                evaluation: evaluation,
                details: details
            )

            self?.logger.enqueue { exposure }
        }

        return Layer(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            logParameterExposure: logExposure,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }
}


// MARK: Private
extension Statsig {
    private func setValuesFromNetwork(_ sdkKey: String, completion: InitCompletion? = nil) {
        network.get(.downloadConfigSpecs) {
            [weak self] (result: DecodedResult<DownloadConfigSpecsResponse>?, error) in

            if let error = error {
                completion?(error)
                return
            }

            guard let result = result else {
                completion?(StatsigError.downloadConfigSpecsFailure)
                return
            }

            self?.store.setAndCacheValues(
                response: result.decoded,
                responseData: result.data,
                sdkKey: sdkKey,
                source: .network
            )

            completion?(nil)
        }
    }

    private func setValuesFromInitialSpecs(_ sdkKey: String, _ initialValues: SynchronousSpecsValue) -> Error? {
        var data: Data?

        if let initialValues = initialValues as? Data {
            data = initialValues
        }
        else if let initalValues = initialValues as? String {
            data = Data(initalValues.utf8)
        }

        guard let data = data else {
            return StatsigError.invalidSynchronousSpecs
        }

        do {
            let decoded = try JSONDecoder()
                .decode(DownloadConfigSpecsResponse.self, from: data)

            store.setAndCacheValues(
                response: decoded,
                responseData: data,
                sdkKey: sdkKey,
                source: .bootstrap
            )

            return nil
        } catch {
            return error
        }
    }

    private func getConfigImpl(_ name: String, _ user: StatsigUser) -> DetailedEvaluation {
        let userInternal = internalizeUser(user, options)
        let detailedEval = evaluator.getConfig(name, userInternal)
        let (evaluation, details) = detailedEval

        logger.enqueue {
            createConfigExposure(
                user: userInternal,
                configName: name,
                evaluation: evaluation,
                details: details
            )
        }

        return detailedEval
    }

    private func trackInitDiagnostics() -> (Error?) -> Void {
        Diagnostics.boot()
        Diagnostics.mark?.overall.start()

        return { error in
            let sourceInfo = self.store.getSourceInfo()
            let lcut = sourceInfo.lcut

            Diagnostics.mark?.overall.end(
                success: error == nil,
                details: [
                    "reason": sourceInfo.source.rawValue,
                    "configSyncTime": lcut,
                    "initTime": lcut,
                    "serverTime": Time.now()
                ],
                errorMessage: nil
            )
            Diagnostics.log(self.logger, context: .initialize)
        }
    }
}
