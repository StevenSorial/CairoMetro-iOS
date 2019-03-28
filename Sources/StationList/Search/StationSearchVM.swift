import Fuse
import RxCocoa
import RxSwift

final class StationSearchVM {
  private(set) var allStations: Observable<[Station]>!
  private(set) var query: AnyObserver<String>!
  private(set) var searchResult: Observable<[StationCellVM]>!
  private(set) var selectIndex: PublishSubject<IndexPath>!

  let fuse: Fuse
  let repo: MetroRepoProtocol

  init(repo: MetroRepoProtocol = MetroSQLRepo()) {
    fuse = Fuse(threshold: 0.5, maxPatternLength: 99, tokenize: true)
    self.repo = repo
    setup()
  }

  private func setup() {
    allStations = repo.getAllStations().asObservable().share(replay: 1)
    selectIndex = PublishSubject<IndexPath>()
    let querySubject = PublishSubject<String>()
    self.query = querySubject.asObserver()

    let queryObservable = querySubject
      .asObservable()
      .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
      .distinctUntilChanged()

    searchResult = Observable
      .combineLatest(queryObservable, allStations) { query, stations in (query, stations) }
      .flatMapLatest { query, stations in
        self.fuse.search(query, in: stations)
      }.map {
        $0.map { StationCellVM(station: $0) }
      }
  }
}
