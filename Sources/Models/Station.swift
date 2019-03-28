import CoreLocation
import DifferenceKit
import Fuse
import GRDB

struct Station: Equatable {

  let id: Int
  private let nameEnglish: String
  private let nameArabic: String
  // swiftlint:disable:next discouraged_optional_boolean
  let isActiveInLine: Bool?
  let indexInLine: Int?
  let location: CLLocation
  private let lat: Double
  private let long: Double

  var primaryName: String {
    Localizable.currentLangCode().lowercased() == "ar" ? nameArabic : nameEnglish
  }

  var secondaryName: String {
    Localizable.currentLangCode().lowercased() == "ar" ? nameEnglish : nameArabic
  }
}

extension Station: Fuseable {
  var properties: [FuseProperty] {
    [
      FuseProperty(value: primaryName),
      FuseProperty(value: secondaryName),
    ]
  }
}

extension Station: Differentiable {
  var differenceIdentifier: Int { id }
}

extension Station: Codable, FetchableRecord {
  enum CodingKeys: String, CodingKey, ColumnExpression {
    case id
    case nameEnglish = "name_english"
    case nameArabic = "name_arabic"
    case isActiveInLine
    case indexInLine
    case lat
    case long
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    nameEnglish = try container.decode(String.self, forKey: .nameEnglish)
    nameArabic = try container.decode(String.self, forKey: .nameArabic)
    isActiveInLine = try? container.decodeIfPresent(Bool.self, forKey: .isActiveInLine)
    indexInLine = try? container.decodeIfPresent(Int.self, forKey: .indexInLine)
    lat = try container.decode(Double.self, forKey: .lat)
    long = try container.decode(Double.self, forKey: .long)
    location = CLLocation(latitude: lat, longitude: long)
  }
}
