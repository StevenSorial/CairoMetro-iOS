import RxSwift
import SwiftyUserDefaults
import UIKit

class MainWindow: UIWindow, ObserverClass {

  let disposeBag = DisposeBag()

  override init(frame: CGRect) {
    super.init(frame: frame)
    _init()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    _init()
  }

  @available(iOS 13.0, *)
  override init(windowScene: UIWindowScene) {
    super.init(windowScene: windowScene)
    _init()
  }

  private func _init() {
    setupBindings()
    #if DEBUG
    installFlexRecognizer()
    #endif
  }

  func setupBindings() {
    Defaults.observe(\.theme)
      .map { $0.newValue! }
      .startWith(Defaults[\.theme])
      .bind(onNext: changeTheme)
      .disposed(by: disposeBag)
  }
}

#if DEBUG
import FLEX

extension MainWindow {
  func installFlexRecognizer() {
    let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(launchFlex))
    recognizer.direction = .down
    recognizer.numberOfTouchesRequired = 3
    recognizer.delegate = self
    addGestureRecognizer(recognizer)
  }

  @objc
  func launchFlex() {
    FLEXManager.shared.isNetworkDebuggingEnabled = true
    if #available(iOS 13.0, *), let windowScene = windowScene {
      FLEXManager.shared.showExplorer(from: windowScene)
    } else {
      FLEXManager.shared.showExplorer()
    }
  }
}

extension MainWindow: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
#endif

extension MainWindow {
  private func changeTheme(to theme: Theme) {
    guard #available(iOS 13.0, *) else { return }
    let style: UIUserInterfaceStyle
    switch theme {
      case .dark: style = .dark
      case .light: style = .light
      default: style = .unspecified
    }
    overrideUserInterfaceStyle = style
  }
}
