// swiftlint:disable file_types_order

import RxSwift

enum Dijkstra {

  static func findTrip(from fromStation: Station,
                       to toStation: Station,
                       in data: [LineWithStations]) -> [LineWithStations] {
    let graph = StationsGraph(data)
    return graph.findTrip(from: fromStation, to: toStation)
  }

  static func findTripAsync(from fromStation: Station,
                            to toStation: Station,
                            in data: [LineWithStations],
                            completion: @escaping ([LineWithStations]) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      let trip = findTrip(from: fromStation, to: toStation, in: data)
      completion(trip)
    }
  }

  static func rxFindTrip(from fromStation: Station,
                         to toStation: Station,
                         in data: [LineWithStations]) -> Single<[LineWithStations]> {
    Single.create { observer in
      findTripAsync(from: fromStation, to: toStation, in: data) { trip in
        observer(.success(trip))
      }
      return Disposables.create()
    }
  }
}

private class StationVertex {
  var stationId: Int
  var lineId: Int
  var neighbors: Set<Connection> = []
  var pathLengthFromStart: Int = .max
  var pathVerticesFromStart: [StationVertex] = []

  init(stationId: Int, lineId: Int) {
    self.stationId = stationId
    self.lineId = lineId
  }

  func clearCache() {
    pathLengthFromStart = .max
    pathVerticesFromStart = []
  }
}

extension StationVertex: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(stationId)
    hasher.combine(lineId)
  }
}

extension StationVertex: Equatable {
  static func == (lhs: StationVertex, rhs: StationVertex) -> Bool {
    lhs.stationId == rhs.stationId
      && lhs.lineId == rhs.lineId
  }
}

private class Connection {
  var vertex: StationVertex
  var weight: Int

  init(vertex: StationVertex, weight: Int) {
    self.vertex = vertex
    self.weight = weight
  }
}

extension Connection: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(vertex)
    hasher.combine(weight)
  }
}

extension Connection: Equatable {
  static func == (lhs: Connection, rhs: Connection) -> Bool {
    lhs.vertex == rhs.vertex
      && lhs.weight == rhs.weight
  }
}

private class StationsGraph {
  private var totalVertices: Set<StationVertex> = []
  private var linesWithStations: [LineWithStations] = []

  init(_ data: [LineWithStations]) {
    self.linesWithStations = data
    _init()
    precondition(linesWithStations.isNotEmpty && totalVertices.isNotEmpty, "Class has empty or incorrect data")
  }

  private func _init() {

    // init
    for lineWithStations in linesWithStations {
      for station in lineWithStations.stations {
        totalVertices.insert(StationVertex(stationId: station.id, lineId: lineWithStations.line.id))
      }
    }

    for lineWithStations in linesWithStations {
      let line = lineWithStations.line
      let stations = lineWithStations.stations
      for (stationIndex, station) in stations.enumerated() {
        let vertex = totalVertices.first { $0.stationId == station.id && $0.lineId == line.id }!
        let neighborVertex = totalVertices.first {
          $0.stationId == stations[stationIndex + 1].id
          && $0.lineId == line.id
        }!
        let selfToNeighborConnection = Connection(vertex: neighborVertex, weight: 1)
        let neighborToSelfConnection = Connection(vertex: vertex, weight: 1)
        vertex.neighbors.insert(selfToNeighborConnection)
        neighborVertex.neighbors.insert(neighborToSelfConnection)
        if stationIndex == stations.count - 2 { break }
      }
    }

    let dups = Dictionary(grouping: totalVertices) { $0.stationId }.filter { $0.value.count > 1 }
    for dup in dups {
      for (index, stationVertex) in dup.value.enumerated() {
        let neighborVertex = dup.value[index + 1]
        let selfToNeighborConnection = Connection(vertex: neighborVertex, weight: 500)
        let neighborToSelfConnection = Connection(vertex: stationVertex, weight: 500)
        stationVertex.neighbors.insert(selfToNeighborConnection)
        neighborVertex.neighbors.insert(neighborToSelfConnection)
        if index == dup.value.count - 2 { break }
      }
    }
  }

  private func clearCache() {
    totalVertices.forEach { $0.clearCache() }
  }

  private func findShortestPaths(from startVertex: StationVertex) {
    clearCache()
    var currentVertices = totalVertices
    startVertex.pathLengthFromStart = 0
    startVertex.pathVerticesFromStart.append(startVertex)
    var currentVertex: StationVertex? = startVertex
    while let vertex = currentVertex {
      currentVertices.remove(vertex)
      let filteredNeighbors = vertex.neighbors.filter { currentVertices.contains($0.vertex) }
      for neighbor in filteredNeighbors {
        let neighborVertex = neighbor.vertex
        let weight = neighbor.weight

        let theoreticNewWeight = vertex.pathLengthFromStart + weight
        if theoreticNewWeight < neighborVertex.pathLengthFromStart {
          neighborVertex.pathLengthFromStart = theoreticNewWeight
          neighborVertex.pathVerticesFromStart = vertex.pathVerticesFromStart
          neighborVertex.pathVerticesFromStart.append(neighborVertex)
        }
      }
      if currentVertices.isEmpty {
        currentVertex = nil
        break
      }
      currentVertex = currentVertices.min { $0.pathLengthFromStart < $1.pathLengthFromStart }
    }
  }

  func findTrip(from departureStation: Station, to destinationStation: Station) -> [LineWithStations] {
    let departureVertices = totalVertices.filter { $0.stationId == departureStation.id }
    guard var departureVertex = departureVertices.first else {
      fatalError("The departure station is not included in the data")
    }

    departureVertex = departureVertices.min {
      let firstLength = findDestinationVertex(from: $0, to: destinationStation).pathLengthFromStart
      let secondLength = findDestinationVertex(from: $1, to: destinationStation).pathLengthFromStart
      return firstLength < secondLength
    }!

    let destinationVertex = findDestinationVertex(from: departureVertex, to: destinationStation)
    return generateTrip(from: departureVertex, to: destinationVertex)
  }

  func findDestinationVertex(from departureVertex: StationVertex, to destinationStation: Station) -> StationVertex {
    findShortestPaths(from: departureVertex)
    let destinationVertices = totalVertices.filter { $0.stationId == destinationStation.id }
    guard var destinationVertex = destinationVertices.first else {
      fatalError("The destination station is not included in the data")
    }
    destinationVertex = destinationVertices.min {
      $0.pathLengthFromStart < $1.pathLengthFromStart
    }!
    return destinationVertex
  }

  func generateTrip(from departureVertex: StationVertex,
                    to destinationVertex: StationVertex) -> [LineWithStations] {
     var trip: [LineWithStations] = []
     for vertex in destinationVertex.pathVerticesFromStart {
       let currentLine = linesWithStations.first { $0.line.id == vertex.lineId }!
       let currentStation = currentLine.stations.first { $0.id == vertex.stationId }!
       if let lineIndex = trip.firstIndex(where: { $0.line.id == currentLine.line.id }) {
         trip[lineIndex].stations.append(currentStation)
       } else {
         trip.append(LineWithStations(line: currentLine.line, stations: [currentStation]))
       }
     }
     for (index, line) in trip.enumerated() where line.stations.count < 2 {
       trip.remove(at: index)
     }
     return trip
   }
}
