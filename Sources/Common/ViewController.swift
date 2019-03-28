import UIKit

protocol ViewController where Self: UIViewController {
  static func instantiate() -> Self
}
