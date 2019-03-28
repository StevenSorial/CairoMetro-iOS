import SwiftyUserDefaults

extension DefaultsKeys {
  var theme: DefaultsKey<Theme> { .init("theme", defaultValue: .system) }
}
