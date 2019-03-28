import RxSwift

final class SelectStationVM {

  private(set) var linesWithStations: Observable<[ListSectionVM]>!
  private(set) var selectIndex: PublishSubject<IndexPath>!
  private let repo: MetroRepoProtocol

  init(repo: MetroRepoProtocol = MetroSQLRepo()) {
    self.repo = repo
    setup()
  }

  private func setup() {
    linesWithStations = repo.getLinesWithStations().asObservable().startWith([]).map { data in
      data.map { ListSectionVM(line: $0.line, stations: $0.stations) }
    }.share(replay: 1)
    selectIndex = PublishSubject()
  }
}
