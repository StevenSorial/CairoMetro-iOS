import DifferenceKit

struct LineWithStations {
  let line: Line
  var stations: [Station]
}

extension LineWithStations: Equatable {
}

extension LineWithStations: Differentiable {
  var differenceIdentifier: Int { line.id }
}
