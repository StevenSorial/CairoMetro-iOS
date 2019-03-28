import AlamofireNetworkActivityIndicator
import FirebaseCore
import GoogleMobileAds
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
                   // swiftlint:disable:next discouraged_optional_collection
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    #if DEBUG
    GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
      "d13c86bfc764b3352ef49a2aace41be5", // iPhone XS
    ]
    #endif
    GADMobileAds.sharedInstance().start()
    Logger.setup()
    applyAppearance()
    NetworkActivityIndicatorManager.shared.isEnabled = true
    NetworkActivityIndicatorManager.shared.startDelay = 0.5
    NetworkActivityIndicatorManager.shared.completionDelay = 0.2
    instantiateWindow()
    return true
  }

  func instantiateWindow() {
    if #available(iOS 13.0, *) {
      Logger.info("Scene delegate should instantiate the window instead of AppDelegate")
    } else {
      Logger.info("instantiating legacy window")
      window = MainWindow(frame: UIScreen.main.bounds)
      window!.rootViewController = MainTabBarController.instantiate()
      window!.makeKeyAndVisible()
    }
  }

  func applyAppearance() {
    Logger.verbose("Applying appearance")
    UINavigationBar.appearance().prefersLargeTitles = true
    UINavigationBar.appearance().isTranslucent = true
    UITabBar.appearance().tintColor = ColorCompat.metroRed
    UITextField.appearance().tintColor = ColorCompat.metroRed
    UITextView.appearance().tintColor = ColorCompat.metroRed
    UINavigationBar.appearance().tintColor = ColorCompat.metroRed
    UISearchBar.appearance().tintColor = ColorCompat.metroRed
    UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = ColorCompat.metroRed
  }

  @available(iOS 13.0, *)
  func application(_ application: UIApplication,
                   configurationForConnecting connectingSceneSession: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    return UISceneConfiguration(
      name: connectingSceneSession.configuration.name!,
      sessionRole: connectingSceneSession.role
    )
  }
}
