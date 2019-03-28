import DifferenceKit

class ListSectionVM {
  let line: Line
  let stationVMs: [StationCellVM]

  init(line: Line, stations: [Station]) {
    self.line = line
    var cellVMs: [StationCellVM] = []
    for (stationIndex, station) in stations.enumerated() {
      var indicator: StationCellVM.PositionIndicator! = nil
      if stationIndex == 0 {
        indicator = .start
      } else if stationIndex == stations.count - 1 {
        indicator = .end
      } else {
        indicator = .middle
      }
      cellVMs.append(StationCellVM(station: station, color: line.color, position: indicator))
    }
    self.stationVMs = cellVMs
  }
}

extension ListSectionVM {
  var differenceKitSection: ArraySection<ListSectionVM, StationCellVM> {
    ArraySection(model: self, elements: stationVMs)
  }
}

extension ListSectionVM: Equatable {
  static func == (lhs: ListSectionVM, rhs: ListSectionVM) -> Bool {
    lhs.line == rhs.line && lhs.stationVMs == rhs.stationVMs
  }
}

extension ListSectionVM: Differentiable {
  var differenceIdentifier: Int { line.id }
}
