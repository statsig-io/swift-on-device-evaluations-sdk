import Foundation

public typealias InitCompletion = (_ error: Error?) -> Void
public typealias ShutdownCompletion = (_ error: Error?) -> Void

@objc
public protocol SynchronousSpecsValue {}

extension NSData: SynchronousSpecsValue {}
extension NSString: SynchronousSpecsValue {}

class StatsigContext {
    let store: SpecStore
    let evaluator: Evaluator
    let network: NetworkService
    let logger: EventLogger
    let sdkKey: String
    let options: StatsigOptions?

    var globalUser: StatsigUser?

    init(_ emitter: StatsigClientEventEmitter, _ sdkKey: String, _ options: StatsigOptions?) {
        store = SpecStore(emitter)
        evaluator = Evaluator(store, emitter)
        network = NetworkService(sdkKey, options)
        logger = EventLogger(options, network, emitter)

        self.sdkKey = sdkKey
        self.options = options
    }
}

public final class Statsig: NSObject {
    let emitter = StatsigClientEventEmitter()

    var context: StatsigContext?

    @objc(sharedInstance)
    public static var shared: Statsig = {
        return Statsig()
    }()

    @objc public override init() {
        super.init()
        subscribeToApplicationLifecycle()
    }

    @objc(initializeWithSDKKey:options:completion:)
    public func initialize(
        _ sdkKey: String,
        options: StatsigOptions? = nil,
        completion: InitCompletion? = nil
    ) {
        let markEnd = Diagnostics.trackInit()

        let context = StatsigContext(emitter, sdkKey, options)
        context.store.loadFromCache(sdkKey)
        self.context = context

        setValuesFromNetwork(context) { [weak context] error in
            markEnd(context?.logger, context?.store.sourceInfo, error)
            completion?(error)
        }
    }

    @objc(initializeSyncWithSDKKey:initialSpecs:options:)
    public func initializeSync(
        _ sdkKey: String,
        initialSpecs: SynchronousSpecsValue,
        options: StatsigOptions? = nil
    ) -> Error? {
        let markEnd = Diagnostics.trackInit()
        let context = StatsigContext(emitter, sdkKey, options)

        let error = setValuesFromInitialSpecs(context, initialSpecs)
        markEnd(context.logger, context.store.sourceInfo, error)
        self.context = context
        return error
    }

    @objc
    public func shutdown(completion: ShutdownCompletion? = nil) {
        context()?.logger.shutdown { err in completion?(err) }
        unsubscribeFromApplicationLifecycle()
    }

    @objc
    public func setGlobalUser(_ user: StatsigUser) {
        context()?.globalUser = user
    }

    @objc
    public func addListener(_ listener: StatsigListening) {
        emitter.addListener(listener)
    }

    @objc
    public func removeListener(_ listener: StatsigListening) {
        emitter.removeListener(listener)
    }

    internal func context(_ caller: String = #function) -> StatsigContext? {
        if context == nil {
            let message = "\(caller) called before Statsig.initialize."
            print("[Statsig]: \(message)")
            emitter.emit(.error, ["message": message])
        }

        return context
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
        guard let context = context() else {
            return .empty(name, .uninitialized())
        }

        let userInternal = getInternalizedUser(context, user)
        let (evaluation, details) = context.evaluator.checkGate(name, userInternal)

        if let userInternal = userInternal {
            context.logger.enqueue{
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
        guard let context = context() else {
            return .empty(name, .uninitialized())
        }

        let (evaluation, details) = getConfigImpl(context, name, user)

        return DynamicConfig(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }

    @objc(getExperiment:forUser:)
    public func getExperiment(_ name: String, _ user: StatsigUser? = nil) -> Experiment {
        guard let context = context() else {
            return .emptyExperiment(name, .uninitialized())
        }

        let (evaluation, details) = getConfigImpl(context, name, user)

        return Experiment(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }

    @objc(getLayer:forUser:)
    public func getLayer(_ name: String, _ user: StatsigUser? = nil) -> Layer {
        guard let context = context() else {
            return .empty(name, .uninitialized())
        }

        let userInternal = getInternalizedUser(context, user)
        let (evaluation, details) = context.evaluator.getLayer(name, userInternal)

        let logExposure: ParameterExposureFunc = { [weak context] layer, parameter in
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

            context?.logger.enqueue { exposure }
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
        guard let context = context() else {
            return
        }

        if let userInternal = getInternalizedUser(context, user) {
            context.logger.enqueue { event.toInternal(userInternal, nil) }
        }
    }

    @objc
    public func flushEvents() {
        context()?.logger.flush()
    }
}


// MARK: Private
extension Statsig {
    private func setValuesFromNetwork(
        _ context: StatsigContext,
        completion: InitCompletion? = nil
    ) {
        context.network.get(.downloadConfigSpecs) {
            [weak context] (result: DecodedResult<DownloadConfigSpecsResponse>?, error) in

            if let error = error {
                completion?(error)
                return
            }

            guard let result = result else {
                completion?(StatsigError.downloadConfigSpecsFailure)
                return
            }

            guard let context = context else {
                return
            }

            context.store.setAndCacheValues(
                response: result.decoded,
                responseData: result.data,
                sdkKey: context.sdkKey,
                source: .network
            )

            completion?(nil)
        }
    }

    private func setValuesFromInitialSpecs(
        _ context: StatsigContext,
        _ initialValues: SynchronousSpecsValue
    ) -> Error? {
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

            context.store.setAndCacheValues(
                response: decoded,
                responseData: data,
                sdkKey: context.sdkKey,
                source: .bootstrap
            )

            return nil
        } catch {
            return error
        }
    }

    private func getConfigImpl(
        _ context: StatsigContext,
        _ name: String,
        _ user: StatsigUser?,
        _ callingFunction: String = #function
    ) -> DetailedEvaluation {
        let userInternal = getInternalizedUser(context, user, callingFunction)
        let detailedEval = context.evaluator.getConfig(name, userInternal)
        let (evaluation, details) = detailedEval

        if let userInternal = userInternal {
            context.logger.enqueue {
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

    private func getInternalizedUser(
        _ context: StatsigContext,
        _ user: StatsigUser?,
        _ callingFunction: String = #function
    ) -> StatsigUserInternal? {
        guard let user = user ?? context.globalUser else {
            return nil
        }

        return StatsigUserInternal(
            user: user,
            environment: context.options?.environment
        )
    }
}
