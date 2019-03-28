import Alamofire
import CoreLocation

enum Router: URLRequestConvertible {

  case nearestStation(origin: CLLocation, destinations: [Station])

  private var method: HTTPMethod {
    switch self {
      case .nearestStation: return .get
    }
  }

  private var path: URL {
    switch self {
      case .nearestStation: return URL(string: "https://maps.googleapis.com/maps/api/distancematrix/json")!
    }
  }

  private var cachePolicy: URLRequest.CachePolicy {
    switch self {
      case .nearestStation: return .useProtocolCachePolicy
    }
  }

  private var timeout: TimeInterval {
    switch self {
      case .nearestStation: return 60
    }
  }

  func asURLRequest() throws -> URLRequest {
    var urlRequest = URLRequest(url: path)
    switch self {
      case .nearestStation(let origin, let stations):
        let params = NearestStationParams(from: origin, to: stations)
        urlRequest = try URLEncodedFormParameterEncoder.default.encode(params, into: urlRequest)
    }
    // HTTP Method
    urlRequest.httpMethod = method.rawValue
    urlRequest.timeoutInterval = timeout
    urlRequest.cachePolicy = cachePolicy
    return urlRequest
  }
}
