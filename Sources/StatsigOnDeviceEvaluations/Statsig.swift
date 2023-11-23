import Foundation

public typealias InitCompletion = (_ error: Error?) -> Void
public typealias ShutdownCompletion = (_ error: Error?) -> Void

@objc
public protocol SynchronousSpecsValue {}

extension NSData: SynchronousSpecsValue {}
extension NSString: SynchronousSpecsValue {}

public final class Statsig: NSObject {
    let store: SpecStore
    let evaluator: Evaluator
    let network: NetworkService
    let logger: EventLogger
    let emitter: StatsigClientEventEmitter

    var hasCalledInit = false
    var options: StatsigOptions?
    var globalUser: StatsigUser?

    @objc(sharedInstance)
    public static var shared: Statsig = {
        return Statsig()
    }()

    @objc public override init() {
        emitter = StatsigClientEventEmitter()
        store = SpecStore(emitter)
        evaluator = Evaluator(store, emitter)
        network = NetworkService()
        logger = EventLogger(network, emitter)
        super.init()

        subscribeToApplicationLifecycle()
    }

    @objc(initializeWithSDKKey:options:completion:)
    public func initialize(
        _ sdkKey: String,
        options: StatsigOptions? = nil,
        completion: InitCompletion? = nil
    ) {
        hasCalledInit = true

        let markEnd = Diagnostics.trackInit()

        self.network.setRequiredFields(sdkKey, options)
        self.logger.options = options
        self.options = options
        self.store.loadFromCache(sdkKey)

        setValuesFromNetwork(sdkKey) { [weak logger, weak store] error in
            markEnd(logger, store?.sourceInfo, error)
            completion?(error)
        }
    }

    @objc(initializeSyncWithSDKKey:initialSpecs:options:)
    public func initializeSync(
        _ sdkKey: String,
        initialSpecs: SynchronousSpecsValue,
        options: StatsigOptions? = nil
    ) -> Error? {
        hasCalledInit = true

        let markEnd = Diagnostics.trackInit()

        self.network.setRequiredFields(sdkKey, options)
        self.logger.options = options
        self.options = options

        let error = setValuesFromInitialSpecs(sdkKey, initialSpecs)
        markEnd(logger, store.sourceInfo, error)
        return error
    }

    @objc
    public func shutdown(completion: ShutdownCompletion? = nil) {
        self.logger.shutdown { err in completion?(err) }
        unsubscribeFromApplicationLifecycle()
    }

    @objc
    public func setGlobalUser(_ user: StatsigUser) {
        globalUser = user
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
    public func checkGate(_ name: String, _ user: StatsigUser? = nil) -> Bool {
        return getFeatureGate(name, user).value
    }

    @objc(getFeatureGate:forUser:)
    public func getFeatureGate(_ name: String, _ user: StatsigUser? = nil) -> FeatureGate {
        let userInternal = internalUserBoundary(user)
        let (evaluation, details) = evaluator.checkGate(name, userInternal)

        if let userInternal = userInternal {
            logger.enqueue{
                createGateExposure(
                    user: userInternal,
                    gateName: name,
                    evaluation: evaluation,
                    details: details
                )
            }
        }

        return FeatureGate(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.boolValue
        )
    }

    @objc(getDynamicConfig:forUser:)
    public func getDynamicConfig(_ name: String, _ user: StatsigUser? = nil) -> DynamicConfig {
        let (evaluation, details) = getConfigImpl(name, user)

        return DynamicConfig(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }

    @objc(getExperiment:forUser:)
    public func getExperiment(_ name: String, _ user: StatsigUser? = nil) -> Experiment {
        let (evaluation, details) = getConfigImpl(name, user)

        return Experiment(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }

    @objc(getLayer:forUser:)
    public func getLayer(_ name: String, _ user: StatsigUser? = nil) -> Layer {
        let userInternal = internalUserBoundary(user)
        let (evaluation, details) = evaluator.getLayer(name, userInternal)

        let logExposure: ParameterExposureFunc = { [weak self] layer, parameter in
            guard let userInternal = userInternal else {
                return
            }

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


// MARK: Logging

extension Statsig {
    @objc(logEvent:forUser:)
    public func logEvent(
        _ event: StatsigEvent,
        _ user: StatsigUser? = nil
    ) {
        if let userInternal = internalUserBoundary(user) {
            logger.enqueue { event.toInternal(userInternal, nil) }
        }
    }

    @objc
    public func flushEvents() {
        logger.flush()
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

    private func getConfigImpl(_ name: String, _ user: StatsigUser?, _ callingFunction: String = #function) -> DetailedEvaluation {
        let userInternal = internalUserBoundary(user, callingFunction)
        let detailedEval = evaluator.getConfig(name, userInternal)
        let (evaluation, details) = detailedEval

        if let userInternal = userInternal {
            logger.enqueue {
                createConfigExposure(
                    user: userInternal,
                    configName: name,
                    evaluation: evaluation,
                    details: details
                )
            }
        }

        return detailedEval
    }


    private func internalUserBoundary(
        _ user: StatsigUser?,
        _ callingFunction: String = #function
    ) -> StatsigUserInternal? {
        reportInitState(callingFunction)

        guard let user = user ?? globalUser else {
            return nil
        }

        return StatsigUserInternal(
            user: user,
            environment: options?.environment
        )
    }

    private func reportInitState(_ callingFunction: String) {
        if hasCalledInit {
            return
        }

        let message = "\(callingFunction) called before Statsig.initialize."
        emitter.emit(.error, ["message": message])
        print("[Statsig]: \(message)")
    }
}
