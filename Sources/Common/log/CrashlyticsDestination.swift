import FirebaseCrashlytics
import SwiftyBeaver

// swiftlint:disable line_length
class CrashlyticsDestination: BaseDestination {
  private static let domain = "CrashlyticsError"
  override var asynchronously: Bool {
    get { false }
    set { _ = newValue }
  }

  override func send(_ level: SwiftyBeaver.Level, msg: String, thread: String, file: String, function: String, line: Int, context: Any? = nil) -> String? {
    let formattedString = super.send(level, msg: msg, thread: thread, file: file, function: function, line: line, context: context)
    guard let str = formattedString else {
      return formattedString
    }
    if level == .error {
      Crashlytics.crashlytics().record(error: NSError(domain: CrashlyticsDestination.domain,
                                                       code: 0,
                                                       userInfo: [NSLocalizedDescriptionKey: msg]))
    } else {
      Crashlytics.crashlytics().log(str)
    }
    return str
  }
}
