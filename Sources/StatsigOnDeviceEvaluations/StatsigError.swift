enum StatsigError: Error {
    case invalidSDKKey
    case invalidUrl
    case invalidPayload
    case invalidSynchronousSpecs
    case noDataReceivedInResponse
    case downloadConfigSpecsFailure
    case initializeNetworkFailure
}
