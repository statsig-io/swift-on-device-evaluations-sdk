import Foundation

public typealias InitCompletion = (_ error: Error?) -> Void

@objc
public protocol SynchronousSpecsValue {}

extension NSData: SynchronousSpecsValue {}
extension NSString: SynchronousSpecsValue {}

public final class StatsigOnDeviceEvaluationsClient: NSObject {
    var options: StatsigOptions?

    let store: SpecStore
    let evaluator: Evaluator
    let network: NetworkService
    let logger: EventLogger
    var emitter: StatsigClientEventEmitter

    @objc(sharedInstance)
    public static var shared: StatsigOnDeviceEvaluationsClient = {
        return StatsigOnDeviceEvaluationsClient()
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
        self.network.initialize(sdkKey, options)
        self.logger.options = options
        self.options = options
        setValuesFromNetwork(completion: completion)
    }

    @objc(initializeSyncWithSDKKey:initialSpecs:options:)
    public func initializeSync(
        _ sdkKey: String,
        initialSpecs: SynchronousSpecsValue,
        options: StatsigOptions? = nil) -> Error? {
        self.network.initialize(sdkKey, options)
        self.logger.options = options
        self.options = options
        return setValuesFromInitialSpecs(initialSpecs)
    }

    @objc(logEvent:forUser:)
    public func logEvent(_ event: StatsigEvent, _ user: StatsigUser) {
        logger.enqueue {
            StatsigEventInternal(
                event: event,
                user: user,
                time: Int64(Date().timeIntervalSince1970 * 1000),
                secondaryExposures: []
            )
        }
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
extension StatsigOnDeviceEvaluationsClient {
    @objc(checkGate:forUser:)
    public func checkGate(_ name: String, _ user: StatsigUser) -> Bool {
        return getFeatureGate(name, user).value
    }

    @objc(getFeatureGate:forUser:)
    public func getFeatureGate(_ name: String, _ user: StatsigUser) -> FeatureGate {
        let (evaluation, details) = evaluator.checkGate(name, user)

        logger.enqueue{
            createGateExposure(
                user: user,
                gateName: name,
                gateValue: evaluation.boolValue,
                ruleID: evaluation.ruleID,
                secondaryExposures: []
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
        let (evaluation, details) = evaluator.getLayer(name, user)

        logger.enqueue {
            createLayerExposure(
                user: user,
                gateName: name,
                gateValue: evaluation.boolValue,
                ruleID: evaluation.ruleID,
                secondaryExposures: []
            )
        }

        return Layer(
            name: name,
            ruleID: evaluation.ruleID,
            evaluationDetails: details,
            value: evaluation.jsonValue?.serializeToDictionary()
        )
    }
}


// MARK: Private
extension StatsigOnDeviceEvaluationsClient {
    private func setValuesFromNetwork(completion: InitCompletion? = nil) {
        network.get(.downloadConfigSpecs) {
            [weak self] (data: DownloadConfigSpecsResponse?, error) in

            if let error = error {
                completion?(error)
                return
            }

            guard let data = data else {
                completion?(StatsigError.downloadConfigSpecsFailure)
                return
            }

            self?.store.setValues(data, source: .network)
            completion?(nil)
        }
    }

    private func setValuesFromInitialSpecs(_ initialValues: SynchronousSpecsValue) -> Error? {
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
            store.setValues(decoded, source: .bootstrap)
            return nil
        } catch {
            return error
        }
    }

    private func getConfigImpl(_ name: String, _ user: StatsigUser) -> DetailedEvaluation {
        let detailedEval = evaluator.getConfig(name, user)
        let evaluation = detailedEval.evaluation

        logger.enqueue {
            createConfigExposure(
                user: user,
                gateName: name,
                gateValue: evaluation.boolValue,
                ruleID: evaluation.ruleID,
                secondaryExposures: []
            )
        }

        return detailedEval
    }
}
