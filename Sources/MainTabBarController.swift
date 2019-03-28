import UIKit

final class MainTabBarController: UITabBarController {

  override func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    view.backgroundColor = ColorCompat.systemBackground
    setVCs()
  }

  func setVCs() {
    let vc1 = StationListVC.instantiate()
    vc1.tabBarItem = UITabBarItem(title: Localizable.stations(), image: R.image.station()!, selectedImage: nil)
    let vc2 = TripVC.instantiate()
    vc2.tabBarItem = UITabBarItem(title: Localizable.tripPath(), image: R.image.trip()!, selectedImage: nil)
    var vc3: UIViewController?
    if #available(iOS 13.0, *) {
      vc3 = SettingsVC.instantiate()
      vc3!.tabBarItem = UITabBarItem(title: Localizable.settings(),
                                     image: UIImage(systemName: "gear"),
                                     selectedImage: nil)
    }
    let viewControllers = [vc1, vc2, vc3].compactMap { $0 }
      .map { UINavigationController(rootViewController: $0) }
      .map { AdBannerVC(hostedVC: $0) }
    setViewControllers(viewControllers, animated: true)
  }
}

extension MainTabBarController: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController,
                        shouldSelect viewController: UIViewController) -> Bool {
    guard let selectedViewController = selectedViewController,
      selectedViewController != viewController,
      let fromView = selectedViewController.view,
      let toView = viewController.view else { return true }

    UIView.transition(from: fromView,
                      to: toView,
                      duration: 0.2,
                      options: .transitionCrossDissolve,
                      completion: nil)
    return true
  }
}

extension MainTabBarController: ViewController {
  static func instantiate() -> MainTabBarController {
    return MainTabBarController()
  }
}
