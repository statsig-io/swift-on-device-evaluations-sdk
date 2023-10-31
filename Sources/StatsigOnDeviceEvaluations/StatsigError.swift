enum StatsigError: Error {
    case invalidSDKKey
    case invalidUrl
    case invalidRequestPayload
    case invalidSynchronousSpecs
    case noDataReceivedInResponse
    case downloadConfigSpecsFailure
    case initializeNetworkFailure
    case failedToDeserializeResponse
}
