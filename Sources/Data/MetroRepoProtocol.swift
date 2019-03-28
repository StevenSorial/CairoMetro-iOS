import RxSwift

protocol MetroRepoProtocol {
  func getAllLines() -> Single<[Line]>
  func getAllStations() -> Single<[Station]>
  func getStationById(id: Int) -> Single<Station>
  func getStationsforLine(line: Line) -> Single<[Station]>
  func getLinesWithStations() -> Single<[LineWithStations]>
}
