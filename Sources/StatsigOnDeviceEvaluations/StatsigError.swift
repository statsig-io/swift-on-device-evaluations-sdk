enum StatsigError: Error {
    case invalidSDKKey
    case invalidUrl
    case invalidRequestPayload
    case invalidSynchronousSpecs
    case failedToParseSpecsValue
    case notYetInitialized
    case noDataReceivedInResponse
    case downloadConfigSpecsFailure
    case lostStatsigContext
    case initializeNetworkFailure
    case failedToDeserializeResponse
}
