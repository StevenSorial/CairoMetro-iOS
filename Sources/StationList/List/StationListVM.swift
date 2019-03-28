import Alamofire
import CoreLocation
import RxCocoa
import RxCoreLocation
import RxSwift

final class StationListVM {

  private(set) var linesWithStations: Observable<[ListSectionVM]>!
  private(set) var selectIndex: PublishSubject<IndexPath>!
  private(set) var nearestStation: Observable<Station>!
  private(set) var nearestTappedObserver: AnyObserver<Void>!
  private var nearestTappedObservable: Observable<Void>!
  var locationBtnStatus: Observable<LocationBtnStatus>!
  private(set) var isLoading: BehaviorSubject<Bool>!
  private let repo: MetroRepoProtocol
  private let locationManager: CLLocationManager

  init(repo: MetroRepoProtocol = MetroSQLRepo(),
       locationManager: CLLocationManager = CLLocationManager()) {

    self.repo = repo
    self.locationManager = locationManager
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    setup()
  }

  private func setup() {
    linesWithStations = repo.getLinesWithStations().asObservable().startWith([]).map { data in
      data.map { ListSectionVM(line: $0.line, stations: $0.stations) }
    }.share(replay: 1)
    selectIndex = PublishSubject()
    isLoading = BehaviorSubject(value: false)

    let nearestTapped = PublishSubject<Void>()
    nearestTappedObservable = nearestTapped.asObservable()
    nearestTappedObserver = nearestTapped.asObserver()

    let allStations = repo.getAllStations().asObservable().share(replay: 1)

    let location = nearestTappedObservable.throttle(.seconds(1), latest: false, scheduler: MainScheduler.instance)
      .flatMapLatest { _ -> Observable<CLAuthorizationEvent> in
        let locManObs = self.locationManager.rx.didChangeAuthorizationWithCurrent
        if CLLocationManager.authorizationStatus() == .notDetermined {
          self.locationManager.requestWhenInUseAuthorization()
          return locManObs.take(2)
        } else {
          return locManObs.take(1)
        }
      }.filter {
        [.authorizedWhenInUse, .authorizedAlways].contains($0.status)
      }.do(onNext: {
        $0.manager.startUpdatingLocation()
      }).flatMapLatest {
        $0.manager.rx.didUpdateLocations.filter { $0.locations.isNotEmpty }.take(1)
      }.do(onNext: {
        $0.manager.stopUpdatingLocation()
      }).map {
        $0.locations.last!
      }

    nearestStation = Observable.combineLatest(location, allStations)
      .do(onNext: { _ in
        self.isLoading.onNext(true)
      }).flatMap {
        self.getNearestStation(from: $0, to: $1)
      }.do(onNext: { _ in
        self.isLoading.onNext(false)
      })

    let locationAuthStatus = locationManager.rx.didChangeAuthorizationWithCurrent

    locationBtnStatus = Observable.combineLatest(locationAuthStatus, isLoading).map { status, isLoading in
      let granted = [.notDetermined, .authorizedWhenInUse, .authorizedAlways].contains(status.status)
      if !granted { return .disabled }
      return isLoading ? .loading : .normal
    }
  }

  private func getNearestStation(from origin: CLLocation, to stations: [Station]) -> Single<Station> {
    let stations = stations.shuffled()
    guard stations.isNotEmpty else { fatalError("Empty destinations") }
    return AF.request(Router.nearestStation(origin: origin, destinations: stations))
      .rxDecodable(of: NearestStationResponse.self)
      .map { response in
        guard let elements = response.rows.first?.elements,
          elements.isNotEmpty,
          elements.count == stations.count else {
            throw NearestStationError.wrongResponseFormat
        }
        let nearestElementWithIndex = elements.enumerated()
          .min { $0.element.distance.value < $1.element.distance.value }!
        return stations[nearestElementWithIndex.offset]
      }.catch {
        Logger.error($0.localizedDescription)
        return Single.just(self.getNearestStationFallback(from: origin, to: stations))
      }
  }

  private func getNearestStationFallback(from origin: CLLocation, to stations: [Station]) -> Station {
    var nearestStation = stations.first!
    for station in stations where
      origin.distance(from: station.location) < origin.distance(from: nearestStation.location) {
        nearestStation = station
    }
    return nearestStation
  }
}

extension StationListVM {
  enum NearestStationError: LocalizedError {
    case wrongResponseFormat
    var errorDescription: String? {
      "NearestStationError: Recieved Response from Google in an unexpected format."
    }
  }
}

extension StationListVM {
  enum LocationBtnStatus {
    case normal
    case disabled
    case loading
  }
}
