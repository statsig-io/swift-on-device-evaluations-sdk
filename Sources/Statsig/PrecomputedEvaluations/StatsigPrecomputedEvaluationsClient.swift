import Foundation

public final class StatsigPrecomputedEvaluationsClient: NSObject {
    public typealias InitCompletion = (_ error: Error?) -> Void

    var options: StatsigOptions?
    var user = StatsigUser(userID: "")

    let store: EvaluationStore
    let network: NetworkService
    let logger: EventLogger
    var emitter: StatsigClientEventEmitter

    @objc(sharedInstance)
    public static var shared: StatsigPrecomputedEvaluationsClient = {
        return StatsigPrecomputedEvaluationsClient()
    }()

    @objc public override init() {
        emitter = StatsigClientEventEmitter()
        store = EvaluationStore()
        network = NetworkService()
        logger = EventLogger(network, emitter)
        super.init()
    }

    @objc(initializeWithSDKKey:user:options:completion:)
    public func initialize(
        _ sdkKey: String,
        user: StatsigUser,
        options: StatsigOptions? = nil,
        completion: InitCompletion? = nil
    ) {
        self.network.sdkKey = sdkKey
        self.logger.options = options
        self.options = options
        setValuesFromNetwork(completion: completion)
    }

//    @objc(initializeSyncWithSDKKey:initialSpecs:options:)
//    public func initializeSync(
//        _ sdkKey: String,
//        initialSpecs: SynchronousSpecsValue,
//        options: StatsigOptions? = nil) -> Error? {
//        self.network.sdkKey = sdkKey
//        self.logger.options = options
//        self.options = options
//        return setValuesFromInitialSpecs(initialSpecs)
//    }

    @objc(logEvent:)
    public func logEvent(_ event: StatsigEvent) {
        logger.enqueue {
            StatsigEventInternal(
                event: event,
                user: self.user,
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
extension StatsigPrecomputedEvaluationsClient {
    @objc(checkGate:)
    public func checkGate(_ name: String) -> Bool {
        return getFeatureGate(name).value
    }

    @objc(getFeatureGate:)
    public func getFeatureGate(_ name: String) -> FeatureGate {
        let (evaluation, details) = store.getEvaluation(.gate, name: name.djb2())

        guard let evaluation = evaluation else {
            return FeatureGate(
                name: name,
                ruleID: "",
                evaluationDetails: details,
                value: false
            )
        }
//        logger.enqueue{
//            createGateExposure(
//                user: user,
//                gateName: name,
//                gateValue: evaluation.boolValue,
//                ruleID: evaluation.ruleID,
//                secondaryExposures: []
//            )
//        }

        return FeatureGate(
            name: name,
            ruleID: evaluation.ruleID ?? "",
            evaluationDetails: details,
            value: evaluation.value.asBool() == true
        )
    }

    @objc(getDynamicConfig:)
    public func getDynamicConfig(_ name: String) -> DynamicConfig {
        let (evaluation, details) = getConfigImpl(name, user)

        return DynamicConfig(
            name: name,
            ruleID: "",
            evaluationDetails: details,
            value: evaluation?.value.serializeToDictionary()
        )
    }

    @objc(getExperiment:)
    public func getExperiment(_ name: String) -> Experiment {
        let (evaluation, details) = getConfigImpl(name, user)

        return Experiment(
            name: name,
            ruleID: "",
            evaluationDetails: details,
            value: evaluation?.value.serializeToDictionary()
        )
    }

    @objc(getLayer:)
    public func getLayer(_ name: String) -> Layer {
        let (evaluation, details) = store.getEvaluation(.layer, name: name)
//
//        logger.enqueue {
//            createLayerExposure(
//                user: user,
//                gateName: name,
//                gateValue: evaluation.boolValue,
//                ruleID: evaluation.ruleID,
//                secondaryExposures: []
//            )
//        }

        return Layer(
            name: name,
            ruleID: "",
            evaluationDetails: details,
            value: evaluation?.value.serializeToDictionary()
        )
    }
}


// MARK: Private
extension StatsigPrecomputedEvaluationsClient {
    private func setValuesFromNetwork(completion: InitCompletion? = nil) {
        network.post(.initialize, payload: [
            "user": user.toLoggable(),
            "hash": "djb2",
        ]) {
            [weak self] (data: InitializeResponse?, error) in

            if let error = error {
                completion?(error)
                return
            }

            guard let data = data else {
                completion?(StatsigError.initializeNetworkFailure)
                return
            }

            self?.store.setValues(data, source: .network)
            completion?(nil)
        }
    }

//    private func setValuesFromInitialSpecs(_ initialValues: SynchronousSpecsValue) -> Error? {
//        var data: Data?
//
//        if let initialValues = initialValues as? Data {
//            data = initialValues
//        }
//        else if let initalValues = initialValues as? String {
//            data = Data(initalValues.utf8)
//        }
//
//        guard let data = data else {
//            return StatsigError.invalidSynchronousSpecs
//        }
//
//        do {
//            let decoded = try JSONDecoder()
//                .decode(DownloadConfigSpecsResponse.self, from: data)
//            store.setValues(decoded, source: .bootstrap)
//            return nil
//        } catch {
//            return error
//        }
//    }

    private func getConfigImpl(_ name: String, _ user: StatsigUser) -> DetailedEvaluatedSpec {
        let detailedEval = store.getEvaluation(.config, name: name)
//        let evaluation = detailedEval.evaluation
//
//        logger.enqueue {
//            createConfigExposure(
//                user: user,
//                gateName: name,
//                gateValue: evaluation.boolValue,
//                ruleID: evaluation.ruleID,
//                secondaryExposures: []
//            )
//        }

        return detailedEval
    }
}
