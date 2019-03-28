import Foundation

enum Setting {
  case theme([Theme])
  case language(String)

  static var allCases: [Setting] {
    [.theme(Theme.allCases), language(Localizable.currentLangName())]
  }
}
