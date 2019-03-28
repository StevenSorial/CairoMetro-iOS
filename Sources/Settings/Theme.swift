import SwiftyUserDefaults

enum Theme: Int {
  case  dark = 1, light = 2, system = 3

  var title: String {
    switch self {
      case .dark: return Localizable.darkTheme()
      case .light: return Localizable.lightTheme()
      case .system: return Localizable.systemTheme()
    }
  }

  var isCurrent: Bool { self == Defaults[\.theme] }
}

extension Theme: CaseIterable { }
extension Theme: DefaultsSerializable { }
