import DifferenceKit
import RxCocoa

class TripSectionVM {
  let line: Line
  let stationVMs: [StationCellVM]

  init(line: Line, stations: [Station], in trip: [LineWithStations]) {
    self.line = line
    var cellVMs: [StationCellVM] = []
    for station in stations {
      var indicator = StationCellVM.PositionIndicator.hidden
      for (sectionIndex, loopSection) in trip.enumerated() {
        for (stationIndex, loopStation) in loopSection.stations.enumerated() where station == loopStation {
          if stationIndex == 0 && sectionIndex == 0 {
            indicator = .start
          } else if stationIndex == loopSection.stations.count - 1 && sectionIndex == trip.count - 1 {
            indicator = .end
          } else {
            indicator = .middle
          }
        }
      }
      cellVMs.append(StationCellVM(station: station, color: line.color, position: indicator))
    }
    self.stationVMs = cellVMs
  }
}

extension TripSectionVM: Equatable {
  static func == (lhs: TripSectionVM, rhs: TripSectionVM) -> Bool {
    lhs.line == rhs.line && lhs.stationVMs == rhs.stationVMs
  }
}

extension TripSectionVM {
  var differenceKitSection: ArraySection<TripSectionVM, StationCellVM> {
    ArraySection(model: self, elements: stationVMs)
  }
}

extension TripSectionVM: Differentiable {
  var differenceIdentifier: Int { line.id }
}
