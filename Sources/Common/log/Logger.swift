import SwiftyBeaver

typealias Logger = SwiftyBeaver

extension Logger {

  #if DEBUG
  static var logFileURL: URL? {
    let fileDestinations = destinations.compactMap { $0 as? FileDestination }
    guard let fileDestination = fileDestinations.first else {
      error("fileDestinations is empty.")
      return nil
    }
    return fileDestination.logFileURL
  }
  #endif

  static func setup() {
    addDestinations()
  }

  private static func addDestinations() {
    guard destinations.isEmpty else { return }
    addDestination(ConsoleDestination())
    #if DEBUG
    addDestination(FileDestination())
    #else
    addDestination(CrashlyticsDestination())
    #endif
    destinations.forEach {
      #if DEBUG
      $0.asynchronously = false
      $0.minLevel = .verbose
      #else
      $0.asynchronously = true
      $0.minLevel = .info
      #endif
    }
  }
}
