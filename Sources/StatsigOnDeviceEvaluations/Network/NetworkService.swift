import Foundation

typealias NetworkCompletion<T: Decodable> = (_ data: T?, _ error: Error?) -> Void

enum Endpoint: String {
    case downloadConfigSpecs = "/v1/download_config_specs"
    case logEvent = "/v1/rgstr"
}

enum Result<T> {
    case error(Error)
    case ok(T)
}

struct DiagnosticsMarkers {
    let network: NetworkMarker?
    let process: ProcessMarker?
}

public class NetworkService {
    private var sdkKey: String? = nil
    private var options: StatsigOptions? = nil

    func initialize(
        _ sdkKey: String,
        _ options: StatsigOptions?
    ) {
        self.sdkKey = sdkKey
        self.options = options
    }

    func get<T>(
        _ endpoint: Endpoint,
        completion: @escaping NetworkCompletion<T>
    ) {
        let result = getRequestForEndpoint(endpoint, sdkKey)

        switch result {
        case .error(let err):
            completion(nil, err)

        case .ok(var request):
            request.httpMethod = "GET"
            send(
                request,
                retries: 0,
                markers: getDiagnosticsMarkerForEndpoint(endpoint),
                completion: completion
            )
        }
    }

    func post<T>(
        _ endpoint: Endpoint,
        payload: [String: Any],
        retries: UInt? = nil,
        completion: @escaping NetworkCompletion<T>
    ) {
        let result = getRequestForEndpoint(endpoint, sdkKey)

        switch result {
        case .error(let err):
            completion(nil, err)

        case .ok(var request):
            guard JSONSerialization.isValidJSONObject(payload),
                  let data = try? JSONSerialization.data(withJSONObject: payload)
            else {
                completion(nil, StatsigError.invalidRequestPayload)
                return
            }

            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            send(
                request,
                retries: retries ?? 0,
                markers: getDiagnosticsMarkerForEndpoint(endpoint),
                completion: completion
            )
        }
    }

    private func send<T>(
        _ request: URLRequest,
        retries: UInt,
        backoffMs: UInt = 1000,
        markers: InitializeMarkers?,
        completion: @escaping NetworkCompletion<T>,
        failedAttempts: UInt = 0
    ) {
        let attempt = failedAttempts + 1

        func onFailure(_ error: Error) {
            if failedAttempts > retries {
                completion(nil, error)
                return
            }

            let backoffSec = Double(backoffMs) / 1000.0
            DispatchQueue.main.asyncAfter(deadline: .now() + backoffSec) { [weak self] in
                self?.send(
                    request,
                    retries: retries,
                    backoffMs: backoffMs * 2,
                    markers: markers,
                    completion: completion,
                    failedAttempts: attempt
                )
            }
        }

        markers?.network.start(attempt: attempt)

        let task = URLSession.shared.dataTask(with: request) {
            [weak markers] data, response, err in

            markers?.network.end(attempt, data, response, err)

            if let error = err {
                return onFailure(error)
            }

            guard let data = data else {
                return onFailure(StatsigError.noDataReceivedInResponse)
            }

            var decodeError: Error?
            var decoded: T?
            do {
                markers?.process.start()
                decoded = try JSONDecoder().decode(T.self, from: data)
            } catch {
                decodeError = error
            }

            let wasDecodingSuccessful = decodeError == nil && decoded != nil
            markers?.process.end(success: wasDecodingSuccessful)

            if wasDecodingSuccessful {
                completion(decoded, nil)
            } else {
                onFailure(decodeError ?? StatsigError.failedToDeserializeResponse)
            }
        }

        task.resume()
    }

    private func getDiagnosticsMarkerForEndpoint(_ endpoint: Endpoint) -> InitializeMarkers? {
        switch endpoint {
        case .downloadConfigSpecs:
            return Diagnostics.mark?.initialize
        default:
            return nil
        }
    }

    private func getRequestForEndpoint(
        _ endpoint: Endpoint,
        _ sdkKey: String?
    ) -> Result<URLRequest> {
        guard let sdkKey = sdkKey else {
            return .error(StatsigError.invalidSDKKey)
        }

        var url: URL?

        switch endpoint {
        case .downloadConfigSpecs:
            url = URL(string: "\(StatsigOptions.Defaults.configSpecAPI)\(sdkKey).json")

            if let options = self.options,
               options.configSpecAPI != StatsigOptions.Defaults.configSpecAPI {
                url = URL(string: options.configSpecAPI)
            }

        case .logEvent:
            url = URL(string: StatsigOptions.Defaults.eventLoggingAPI)

            if let options = self.options,
               options.eventLoggingAPI != StatsigOptions.Defaults.eventLoggingAPI {
                url = URL(string: options.eventLoggingAPI)
            }
        }

        guard let url = url else {
            return .error(StatsigError.invalidUrl)
        }

        var request = URLRequest(url: url)

        request.setValue(sdkKey, forHTTPHeaderField: Headers.StatsigAPIKey)
        request.setValue("ios-on-device-eval", forHTTPHeaderField: Headers.StatsigSDKType)
        request.setValue("1.0.0", forHTTPHeaderField: Headers.StatsigSDKVersion)
        request.setValue("\(Time.now())", forHTTPHeaderField: Headers.StatsigClientTime)

        return .ok(request)
    }
}

fileprivate enum Headers {
    static let StatsigAPIKey = "STATSIG-API-KEY"
    static let StatsigClientTime = "STATSIG-CLIENT-TIME"
    static let StatsigSDKType = "STATSIG-SDK-TYPE"
    static let StatsigSDKVersion = "STATSIG-SDK-VERSION"
}
