import RxCocoa
import RxSwift

final class TripVM {

  private let repo: MetroRepoProtocol
  let destinationTapped: PublishSubject<Destination>
  let fromStation: BehaviorRelay<Station?>
  let toStation: BehaviorRelay<Station?>
  var linesWithStations: Observable<[LineWithStations]>
  let trip: Observable<[TripSectionVM]>
  let price: Observable<String>

  init(repo: MetroRepoProtocol = MetroSQLRepo()) {
    self.repo = repo
    destinationTapped = PublishSubject()
    fromStation = BehaviorRelay(value: nil)
    toStation = BehaviorRelay(value: nil)
    linesWithStations = repo.getLinesWithStations().asObservable().share(replay: 1)
    let trip = Observable.combineLatest(fromStation, toStation, linesWithStations)
      .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
      .map { tuple in (tuple.0, tuple.1, tuple.2) }
      .filter { fromStation, toStation, _ in
        fromStation != nil && toStation != nil
      }.flatMapLatest { fromStation, toStation, linesWithStations in
        Dijkstra.rxFindTrip(from: fromStation!, to: toStation!, in: linesWithStations).asObservable()
      }.share(replay: 1)

    price = trip.map {
      let price = calculatePrice(for: $0)
      return formatPrice(price)
    }

    self.trip = trip.map { trip in
      trip.map { TripSectionVM(line: $0.line, stations: $0.stations, in: trip) }
    }
  }
}

private func calculatePrice(for trip: [LineWithStations]) -> Double {
  var stations: [Station] = []
  for tripLine in trip {
    for tripStation in tripLine.stations where !stations.contains(where: { $0.id == tripStation.id }) {
      stations.append(tripStation)
    }
  }

  let withThirdLine = trip.map { $0.line }.contains { $0.id == 3 }
  let price: Double
  if (1...9).contains(stations.count) {
    price = withThirdLine ? 7 : 5
  } else if (10...16).contains(stations.count) {
    price = withThirdLine ? 10 : 7
  } else if (17...).contains(stations.count) {
    price = withThirdLine ? 12 : 10
  } else {
    price = 0
  }
  return price
}

private func formatPrice(_ price: Double) -> String {
  let currencyFormatter = NumberFormatter()
  currencyFormatter.numberStyle = .currency
  currencyFormatter.currencyCode = "EGP"
  currencyFormatter.negativePrefix = "\(currencyFormatter.negativePrefix!) "
  currencyFormatter.positivePrefix = "\(currencyFormatter.positivePrefix!) "
  return currencyFormatter.string(from: NSNumber(value: price))!
}

extension TripVM {
  enum Destination {
    // swiftlint:disable:next identifier_name
    case from, to
  }
}
