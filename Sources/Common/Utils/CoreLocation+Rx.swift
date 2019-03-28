import CoreLocation
import RxCocoa
import RxCoreLocation
import RxSwift

extension Reactive where Base: CLLocationManager {
  public var didChangeAuthorizationWithCurrent: ControlEvent<CLAuthorizationEvent> {
    let source = didChangeAuthorization.startWith((base, CLLocationManager.authorizationStatus()))
    return ControlEvent(events: source)
  }
}
