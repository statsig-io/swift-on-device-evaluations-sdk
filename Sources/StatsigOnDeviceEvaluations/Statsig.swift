import Foundation

public typealias UpdateCompletion = (_ error: Error?) -> Void
public typealias InitCompletion = UpdateCompletion
public typealias ShutdownCompletion = (_ error: Error?) -> Void

class StatsigContext {
    let store: SpecStore
    let evaluator: Evaluator
    let network: NetworkService
    let logger: EventLogger
    let sdkKey: String
    let options: StatsigOptions?
    
    var globalUser: StatsigUser?
    var bgUpdatesHandle: StatsigUpdatesHandle?
    
    init(_ emitter: StatsigClientEventEmitter, _ sdkKey: String, _ options: StatsigOptions?) {
        store = SpecStore(emitter)
        evaluator = Evaluator(
            store,
            emitter,
            options?.userPersistentStorage,
            options?.overrideAdapter
        )
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
            markEnd(context?.logger, context?.store.getSourceInfo(), error)
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
        
        let error = setValuesFromBootstrap(context, initialSpecs)
        markEnd(context.logger, context.store.getSourceInfo(), error)
        self.context = context
        return error
    }
    
    @objc
    public func shutdown(completion: ShutdownCompletion? = nil) {
        if let context = getContext() {
            context.bgUpdatesHandle?.cancel()
            context.logger.shutdown { err in completion?(err) }
        }
        unsubscribeFromApplicationLifecycle()
    }
    
    @objc
    public func setGlobalUser(_ user: StatsigUser) {
        getContext()?.globalUser = user
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

// MARK: Post-Init Syncing

extension Statsig {
    @objc public func update(completion: UpdateCompletion? = nil) {
        guard let context = getContext() else {
            completion?(StatsigError.notYetInitialized)
            return
        }
        
        setValuesFromNetwork(context, completion: completion)
    }
    
    @objc public func updateSync(updatedSpecs: SynchronousSpecsValue) -> Error? {
        guard let context = getContext() else {
            return StatsigError.notYetInitialized
        }
        
        return setValuesFromBootstrap(context, updatedSpecs)
    }
    
    @objc
    public func scheduleBackgroundUpdates(intervalSeconds: TimeInterval = Constants.ONE_HOUR_IN_SECONDS) -> StatsigUpdatesHandle? {
        guard let context = getContext() else {
            emitter.emitError("Cannot schedule background updates before Statsig is initialized.")
            return nil
        }
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + intervalSeconds, repeating: intervalSeconds)
        
        timer.setEventHandler { [weak self] in
            self?.update { error in
                if let error = error {
                    self?.emitter.emitError("Background update failed: \(error.localizedDescription)")
                }
            }
        }
        
        timer.resume()
        
        context.bgUpdatesHandle?.cancel()
        context.bgUpdatesHandle = StatsigUpdatesHandle(timer)
        return context.bgUpdatesHandle
    }
}

// MARK: Check APIs

extension Statsig {
    @objc(checkGate:forUser:options:)
    public func checkGate(
        _ name: String,
        _ user: StatsigUser? = nil,
        _ options: GetFeatureGateOptions? = nil
    ) -> Bool {
        return getFeatureGate(name, user, options).value
    }
    
    @objc(getFeatureGate:forUser:options:)
    public func getFeatureGate(
        _ name: String,
        _ user: StatsigUser? = nil,
        _ options: GetFeatureGateOptions? = nil
    ) -> FeatureGate {
        guard let context = getContext() else {
            return .empty(name, .uninitialized())
        }
        
        guard let userInternal = getInternalizedUser(context, user) else {
            return .empty(name, .userError(context.store.getSourceInfo()))
        }
        
        let (evaluation, details) = context.evaluator.checkGate(name, userInternal, options)
        
        if (options?.disableExposureLogging != true) {
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
    
    @objc(getDynamicConfig:forUser:options:)
    public func getDynamicConfig(
        _ name: String,
        _ user: StatsigUser? = nil,
        _ options: GetDynamicConfigOptions? = nil
    ) -> DynamicConfig {
        guard let context = getContext() else {
            return .empty(name, .uninitialized())
        }
        
        guard let userInternal = getInternalizedUser(context, user) else {
            return .empty(name, .userError(context.store.getSourceInfo()))
        }
        
        let detailedEval = context.evaluator.getConfig(name, userInternal)
        let (evaluation, details) = detailedEval
        
        if (options?.disableExposureLogging != true) {
            context.logger.enqueue {
                createConfigExposure(
                    user: userInternal,
                    configName: name,
                    evaluation: evaluation,
                    details: details
                )
            }
        }
        
        return DynamicConfig(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary(),
            groupName: evaluation.groupName
        )
    }
    
    @objc(getExperiment:forUser:options:)
    public func getExperiment(
        _ name: String,
        _ user: StatsigUser? = nil,
        _ options: GetExperimentOptions? = nil
    ) -> Experiment {
        guard let context = getContext() else {
            return .empty(name, .uninitialized())
        }
        
        guard let userInternal = getInternalizedUser(context, user) else {
            return .empty(name, .userError(context.store.getSourceInfo()))
        }
        
        let detailedEval = context.evaluator.getExperiment(name, userInternal, options)
        let (evaluation, details) = detailedEval
        
        if (options?.disableExposureLogging != true) {
            context.logger.enqueue {
                createConfigExposure(
                    user: userInternal,
                    configName: name,
                    evaluation: evaluation,
                    details: details
                )
            }
        }
        
        return Experiment(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary(),
            groupName: evaluation.groupName
        )
    }
    
    @objc(getLayer:forUser:options:)
    public func getLayer(
        _ name: String,
        _ user: StatsigUser? = nil,
        _ options: GetLayerOptions? = nil
    ) -> Layer {
        guard let context = getContext() else {
            return .empty(name, .uninitialized())
        }
        
        guard let userInternal = getInternalizedUser(context, user) else {
            return .empty(name, .userError(context.store.getSourceInfo()))
        }
        
        let (evaluation, details) = context.evaluator.getLayer(name, userInternal, options: options)
        
        let logExposure: ParameterExposureFunc? = options?.disableExposureLogging != true
        ? { [weak context] layer, parameter in
            let exposure = createLayerExposure(
                user: userInternal,
                layerName: name,
                parameter: parameter,
                evaluation: evaluation,
                details: details
            )
            
            context?.logger.enqueue { exposure }
        } : nil
        
        return Layer(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            logParameterExposure: logExposure,
            value: evaluation.jsonValue?.serializeToDictionary(),
            allocatedExperimentName: evaluation.configDelegate,
            groupName: evaluation.groupName
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
        guard let context = getContext() else {
            return
        }
        
        if let userInternal = getInternalizedUser(context, user) {
            context.logger.enqueue { event.toInternal(userInternal, nil) }
        }
    }
    
    @objc
    public func flushEvents() {
        getContext()?.logger.flush()
    }
}

// MARK: User Persistent Values

extension Statsig {
    @objc(loadUserPersistedValuesAsync:forUser:completion:)
    public func loadUserPersistedValuesAsync(
        _ idType: String,
        _ user: StatsigUser? = nil,
        _ completion: @escaping (UserPersistedValues?) -> Void
    ) {
        guard
            let context = getContext(),
            let storage = context.options?.userPersistentStorage,
            let userInternal = getInternalizedUser(context, user)
        else {
            completion(nil)
            return
        }
        
        let key = getStorageKey(user: userInternal, idType: idType)
        storage.loadAsync(key, completion)
    }
    
    @objc(loadUserPersistedValues:forUser:)
    public func loadUserPersistedValues(
        _ idType: String,
        _ user: StatsigUser? = nil
    ) -> UserPersistedValues? {
        guard
            let context = getContext(),
            let userInternal = getInternalizedUser(context, user)
        else {
            return nil
        }
        
        let key = getStorageKey(user: userInternal, idType: idType)
        return context
            .options?
            .userPersistentStorage?
            .load(key)
    }
}


// MARK: Private
extension Statsig {
    private func setValuesFromNetwork(
        _ context: StatsigContext,
        completion: UpdateCompletion? = nil
    ) {
        var params: [String: String]? = nil
        let lcut = context.store.getSourceInfo().lcut
        if lcut > 0 {
            params = ["sinceTime": String(lcut)]
        }
        
        context.network.get(.downloadConfigSpecs, params) {
            [weak context] (result: DecodedResult<SpecsResponse>?, error) in
            
            if completion == nil {
                print("!!!!!!!!Err")
            }
            
            if let error = error {
                completion?(error)
                return
            }
            
            guard let result = result else {
                completion?(StatsigError.downloadConfigSpecsFailure)
                return
            }
            
            switch result.decoded {
            case .full(let response):
                guard let context = context else {
                    completion?(StatsigError.lostStatsigContext)
                    return
                }
                
                context.store.setAndCacheValues(
                    response: response,
                    responseData: result.data,
                    sdkKey: context.sdkKey,
                    source: .network
                )
                
                completion?(nil)
                return
                
            case .noUpdates:
                completion?(nil)
                return
            }
        }
    }
    
    private func setValuesFromBootstrap(
        _ context: StatsigContext,
        _ value: SynchronousSpecsValue
    ) -> Error? {
        let (result, error) = parseSpecsValue(value)
        
        guard error == nil, let result = result else {
            return error ?? StatsigError.invalidSynchronousSpecs
        }
        
        context.store.setAndCacheValues(
            response: result.response,
            responseData: result.raw,
            sdkKey: context.sdkKey,
            source: .bootstrap
        )
        
        return nil
    }
    
    private func getContext(_ caller: String = #function) -> StatsigContext? {
        if context == nil {
            emitter.emitError("\(caller) called before Statsig.initialize.")
        }
        
        return context
    }
    
    private func getInternalizedUser(
        _ context: StatsigContext,
        _ user: StatsigUser?,
        _ caller: String = #function
    ) -> StatsigUserInternal? {
        guard let user = user ?? context.globalUser else {
            emitter.emitError("No user given when calling \(caller)."
                              + " Please provide a StatsigUser or call setGlobalUser.")
            return nil
        }
        
        return StatsigUserInternal(
            user: user,
            environment: context.options?.environment
        )
    }
    
}
