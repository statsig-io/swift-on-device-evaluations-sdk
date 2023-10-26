import Foundation

typealias NetworkCompletion<T: Decodable> = (_ data: T?, _ error: Error?) -> Void

enum Endpoint: String {
    case downloadConfigSpecs = "/v1/download_config_specs"
    case initialize = "/v1/initialize"
    case logEvent = "/v1/rgstr"
}

let defaultLogEventUrl = "https://api.statsig.com/v1/rgstr"
let defaultInitializeUrl = "https://api.statsig.com/v1/initialize"

enum Result<T> {
    case error(Error)
    case ok(T)
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
            send(request, retries: 0, completion: completion)
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
                completion(nil, StatsigError.invalidPayload)
                return
            }

            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            send(request, retries: retries ?? 0, completion: completion)
        }
    }

    private func send<T>(
        _ request: URLRequest,
        retries: UInt,
        backoffMs: UInt = 1000,
        completion: @escaping NetworkCompletion<T>
    ) {
        func onFailure(_ error: Error) {
            if retries <= 0 {
                completion(nil, error)
                return
            }

            let backoffSec = Double(backoffMs) / 1000.0
            DispatchQueue.main.asyncAfter(deadline: .now() + backoffSec) { [weak self] in
                self?.send(
                    request,
                    retries: retries - 1,
                    backoffMs: backoffMs * 2,
                    completion: completion
                )
            }
        }

        let task = URLSession.shared.dataTask(with: request) {
            data, response, err in

            if let error = err {
                return onFailure(error)
            }

            guard let data = data else {
                return onFailure(StatsigError.noDataReceivedInResponse)
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(decoded, nil)
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
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
            if let options = self.options,
                options.configSpecAPI != StatsigOptions.Defaults.configSpecAPI {
                url = URL(string: options.configSpecAPI)
            } else {
                url = URL(string: "\(StatsigOptions.Defaults.configSpecAPI)\(sdkKey).json")
            }
        case .initialize:
            url = URL(string: defaultInitializeUrl)
        case .logEvent:
            url = URL(string: defaultLogEventUrl)
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
