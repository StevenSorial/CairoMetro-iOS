import CoreLocation
import UIKit

typealias Localizable = R.string.localizable
typealias Color = UIColor
var mainStoryboard: _R.storyboard.main { R.storyboard.main }

@discardableResult
func with<T>(_ item: T, block: (inout T) throws -> Void) rethrows -> T {
  var this = item
  try block(&this)
  return this
}

extension UILabel {
  func setAutoScaledFont(forTextStyle style: UIFont.TextStyle) {
    font = UIFont.preferredFont(forTextStyle: style)
    adjustsFontForContentSizeCategory = true
  }
}

extension IndexPath {
  static let zero = IndexPath(row: 0, section: 0)
}

extension String {
  var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
  var isBlank: Bool { trimmed.isEmpty }
}

extension Optional where Wrapped == String {
  var isNilOrEmpty: Bool { self?.isEmpty ?? true }
  var isNilOrBlank: Bool { self?.isBlank ?? true }
}

extension CLLocation {
  var lat: CLLocationDegrees { coordinate.latitude }
  var lng: CLLocationDegrees { coordinate.longitude }
  var coordinatesByCommas: String { "\(lat),\(lng)" }
}

extension Collection {
  var isNotEmpty: Bool { !isEmpty }
}

extension Sequence {
  func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
    return map { $0[keyPath: keyPath] }
  }

  func sorted<T: Comparable>(on keyPath: KeyPath<Element, T>,
                             by areInIncreasingOrder: (T, T) -> Bool) -> [Element] {
    return sorted { areInIncreasingOrder($0[keyPath: keyPath], $1[keyPath: keyPath]) }
  }
}

extension UIButton {
  @IBInspectable var adjustsFontForContentSizeCategory: Bool {
    get { self.titleLabel?.adjustsFontForContentSizeCategory ?? false }
    set { self.titleLabel?.adjustsFontForContentSizeCategory = newValue }
  }

  @IBInspectable var numberOfLines: Int {
    get { self.titleLabel?.numberOfLines ?? 1 }
    set { self.titleLabel?.numberOfLines = newValue }
  }
}

extension UIView {
  var allSubViews: [UIView] {
    var result = subviews
    result.forEach { result.append(contentsOf: $0.allSubViews) }
    return result
  }

  func typedSubViews<T: UIView>(of type: T.Type = T.self) -> [T] {
    return allSubViews.compactMap { $0 as? T }
  }

  public func pin(to parent: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      leadingAnchor.constraint(equalTo: parent.leadingAnchor),
      trailingAnchor.constraint(equalTo: parent.trailingAnchor),
      topAnchor.constraint(equalTo: parent.topAnchor),
      bottomAnchor.constraint(equalTo: parent.bottomAnchor),
    ])
  }
}

extension UIViewController {
  func addChildVC(_ child: UIViewController, into view: UIView) {
    addChild(child)
    view.addSubview(child.view)
    child.view.pin(to: view)
    child.didMove(toParent: self)
  }

  func removeFromParentVC() {
    guard parent != nil else { return }
    willMove(toParent: nil)
    view.removeFromSuperview()
    removeFromParent()
  }
}

extension UIApplication {
  static var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
  }

  static var appBuild: String {
    Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
  }
}
