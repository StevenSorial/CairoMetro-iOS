import CoreLocation

struct NearestStationParams: Encodable {
  private let origins: String
  private let destinations: String
  private let key: String

  init(from origin: CLLocation, to stations: [Station]) {
    key = Keys.mapsDistanceMatrix
    origins = origin.coordinatesByCommas
    destinations = stations
      .map { $0.location.coordinatesByCommas }
      .joined(separator: "|")
  }
}
