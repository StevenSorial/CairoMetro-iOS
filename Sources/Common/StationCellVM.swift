import DifferenceKit
import RxSwift

class StationCellVM {
  let station: Station

  let color: Color
  let positionIndicator: PositionIndicator

  init(station: Station, color: Color = .clear, position: PositionIndicator = .hidden) {
    self.station = station
    self.color = color
    self.positionIndicator = position
  }
}

extension StationCellVM: Equatable {
  static func == (lhs: StationCellVM, rhs: StationCellVM) -> Bool {
    lhs.station == rhs.station
  }
}

extension StationCellVM: Differentiable {
  var differenceIdentifier: Int { station.id }
}

extension StationCellVM {
  enum PositionIndicator {
    case start, middle, end, point, hidden
  }
}
