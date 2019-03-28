// swiftlint:disable file_types_order

struct NearestStationResponse {
  let destinationAddresses: [String]
  let originAddresses: [String]
  let rows: [Row]
  let status: String
}

extension NearestStationResponse: Codable {
  enum CodingKeys: String, CodingKey {
    case destinationAddresses = "destination_addresses"
    case originAddresses = "origin_addresses"
    case rows
    case status
  }
}

struct Row: Codable {
  let elements: [Element]
}

struct Element: Codable {
  let distance: Value
  let duration: Value
  let status: String
}

struct Value: Codable {
  let text: String
  let value: Int
}
