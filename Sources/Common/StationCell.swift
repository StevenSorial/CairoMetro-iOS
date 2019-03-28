import RxSwift
import UIKit

final class StationCell: UITableViewCell {

  @IBOutlet private weak var titleLbl: UILabel!
  @IBOutlet private weak var subtitleLbl: UILabel!
  @IBOutlet private weak var circleIV: UIImageView!
  @IBOutlet private weak var titleStack: UIStackView!
  @IBOutlet private weak var upperLineIV: UIImageView!
  @IBOutlet private weak var lowerLineIV: UIImageView!

  func bind(to vm: StationCellVM) {
    titleLbl.text = vm.station.primaryName
    subtitleLbl.text = vm.station.secondaryName
    changeColor(to: vm.color)
    changePositionIndicator(to: vm.positionIndicator)
  }

  private func changePositionIndicator(to newPosition: StationCellVM.PositionIndicator) {
    switch newPosition {
      case .start:
        upperLineIV.alpha = 0
        circleIV.alpha = 1
        lowerLineIV.alpha = 1
      case .middle:
        upperLineIV.alpha = 1
        circleIV.alpha = 1
        lowerLineIV.alpha = 1
      case .end:
        upperLineIV.alpha = 1
        circleIV.alpha = 1
        lowerLineIV.alpha = 0
      case .hidden:
        upperLineIV.alpha = 0
        circleIV.alpha = 0
        lowerLineIV.alpha = 0
      case .point:
        upperLineIV.alpha = 0
        circleIV.alpha = 1
        lowerLineIV.alpha = 0
    }
  }

  private func changeColor(to color: UIColor) {
    circleIV.tintColor = color
    upperLineIV.tintColor = color
    lowerLineIV.tintColor = color
  }

  func blink() {
    let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
    animation.fromValue = 1.0
    animation.toValue = 0
    animation.duration = 0.35
    animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
    animation.autoreverses = true
    animation.repeatCount = 2
    animation.isRemovedOnCompletion = true
    titleStack.layer.add(animation, forKey: #keyPath(CALayer.opacity))
  }
}
