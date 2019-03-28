import DifferenceKit
import GRDB

struct Line {
  let id: Int
  private let nameEnglish: String
  private let nameArabic: String
  let startTerminalId: Int
  let endTerminalId: Int

  var localizedName: String {
    Localizable.currentLangCode().lowercased() == "ar" ? nameArabic : nameEnglish
  }

  var color: Color {
    switch id {
      case 1: return ColorCompat.firstLineColor
      case 2: return ColorCompat.secondLineColor
      case 3: return ColorCompat.thirdLineColor
      default: fatalError("Unknown Line")
    }
  }
}

extension Line: Equatable {
}

extension Line: Differentiable {
  var differenceIdentifier: Int { id }
}

extension Line: Codable, FetchableRecord {
  enum CodingKeys: String, CodingKey, ColumnExpression {
    case id
    case nameEnglish
    case nameArabic
    case startTerminalId
    case endTerminalId
  }
}
