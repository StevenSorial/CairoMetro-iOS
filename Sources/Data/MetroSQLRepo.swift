import GRDB
import RxGRDB
import RxSwift

class MetroSQLRepo: MetroRepoProtocol {
  func getAllLines() -> Single<[Line]> {
    MetroSQLRepo.db.rx.read { db in
      try Line.fetchAll(db, sql: "SELECT * FROM line;")
    }
  }

  func getAllStations() -> Single<[Station]> {
    MetroSQLRepo.db.rx.read { db in
      try Station.fetchAll(db, sql: "SELECT * FROM station;")
    }
  }

  func getStationById(id: Int) -> Single<Station> {
    MetroSQLRepo.db.rx.read { db in
      try Station.fetchOne(db, sql: "SELECT * FROM station WHERE id = ?;", arguments: [id])!
    }
  }

  func getStationsforLine(line: Line) -> Single<[Station]> {
    MetroSQLRepo.db.rx.read { db in
      try MetroSQLRepo.getStationsforLine(db: db, line: line)
    }
  }

  func getLinesWithStations() -> Single<[LineWithStations]> {
    Single.create { subscriber in
      MetroSQLRepo.db.asyncRead { db in
        do {
          let lines = try Line.fetchAll(db.get(), sql: "SELECT * FROM line;")
          var linesWithStations: [LineWithStations] = []
          for line in lines {
            let stations = try MetroSQLRepo.getStationsforLine(db: db.get(), line: line)
            if !stations.isEmpty {
              linesWithStations.append(LineWithStations(line: line, stations: stations))
            }
          }
          subscriber(.success(linesWithStations))
        } catch {
          subscriber(.failure(error))
        }
      }
      return Disposables.create()
    }
  }
}

extension MetroSQLRepo {
  private static func getStationsforLine(db: Database, line: Line) throws -> [Station] {
    let sql = """
    SELECT * FROM station
    JOIN line_station
      ON line_station.station_id = station.id
      AND line_station.line_id = ?
    ORDER BY line_station.indexInLine;
    """
    return try Station.fetchAll(db, sql: sql, arguments: [line.id])
    .filter { $0.isActiveInLine == true && $0.indexInLine != nil }
  }
}

extension MetroSQLRepo {
  private static let db: DatabasePool = {
    do {
      var config = Configuration()
      config.readonly = true
      let db = try DatabasePool(path: R.file.metroSqlite()!.absoluteString, configuration: config)
      return db
    } catch {
      fatalError("error opening db: \(error.localizedDescription)")
    }
  }()
}
