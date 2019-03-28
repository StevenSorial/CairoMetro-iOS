import RxSwift
import UIKit

public protocol ObserverClass where Self: AnyObject {
  var disposeBag: DisposeBag { get }
  func setupBindings()
}
