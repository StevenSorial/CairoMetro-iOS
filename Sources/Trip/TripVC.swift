import DifferenceKit
import RxSwift
import UIKit

final class TripVC: UIViewController, ObserverClass {

  let disposeBag = DisposeBag()
  private let vm = TripVM()
  private var viewedTrip: [TripSectionVM] = []
  private var allData: [LineWithStations] = []

  @IBOutlet private weak var tfStack: UIStackView!
  @IBOutlet private weak var fromLbl: UILabel!
  @IBOutlet private weak var toLbl: UILabel!
  @IBOutlet private weak var fromBtn: UIButton!
  @IBOutlet private weak var toBtn: UIButton!
  @IBOutlet private weak var priceLbl: UILabel!
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var flipBtn: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupBindings()
  }

  func setupUI() {
    title = Localizable.tripPath()
    definesPresentationContext = true
    flipBtn.tintColor = ColorCompat.metroRed
    fromLbl.text = Localizable.from()
    fromBtn.titleLabel?.textAlignment = .center
    fromBtn.setTitleColor(ColorCompat.metroRed, for: .normal)
    toLbl.text = Localizable.to()
    toBtn.setTitleColor(ColorCompat.metroRed, for: .normal)
    toBtn.titleLabel?.textAlignment = .center
    tableView.separatorStyle = .none
    tableView.allowsSelection = false
    tableView.rowHeight = 70
    tableView.keyboardDismissMode = .onDrag
    tableView.sectionHeaderHeight = 35
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(R.nib.stationCell)
  }

  // swiftlint:disable:next function_body_length
  func setupBindings() {
    vm.linesWithStations.subscribe(onNext: {
      self.allData = $0
    }).disposed(by: disposeBag)

    fromBtn.rx.tap
      .map { .from }
      .bind(to: vm.destinationTapped)
      .disposed(by: disposeBag)

    toBtn.rx.tap
      .map { .to }
      .bind(to: vm.destinationTapped)
      .disposed(by: disposeBag)

    vm.destinationTapped.filter { $0 == .from }
      .flatMapLatest {_ -> Observable<Station> in
        let vc = SelectStationVC.instantiate()
        self.present(AdBannerVC(hostedVC: UINavigationController(rootViewController: vc)), animated: true)
        return vc.stationObservable
      }.bind(to: vm.fromStation)
      .disposed(by: disposeBag)

    vm.destinationTapped.filter { $0 == .to }
      .flatMapLatest {_ -> Observable<Station> in
        let vc = SelectStationVC.instantiate()
        self.present(AdBannerVC(hostedVC: UINavigationController(rootViewController: vc)), animated: true)
        return vc.stationObservable
      }.bind(to: vm.toStation)
      .disposed(by: disposeBag)

    vm.fromStation
      .map { $0?.primaryName ?? Localizable.chooseDeparture() }
      .bind(to: fromBtn.rx.title())
      .disposed(by: disposeBag)

    vm.toStation
      .map { $0?.primaryName ?? Localizable.chooseDestination() }
      .bind(to: toBtn.rx.title())
      .disposed(by: disposeBag)

    flipBtn.rx.tap.subscribe(onNext: {
      UIView.animate(
        withDuration: 0.3,
        delay: 0,
        options: .curveEaseOut,
        animations: {
          self.flipBtn.transform = self.flipBtn.transform.scaledBy(x: 1, y: -1)
        })
      let fromStation = self.vm.fromStation.value
      self.vm.fromStation.accept(self.vm.toStation.value)
      self.vm.toStation.accept(fromStation)
    }).disposed(by: disposeBag)

    vm.trip
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: {
      self.reload(with: $0)
    }).disposed(by: disposeBag)

    vm.price.bind(to: priceLbl.rx.text).disposed(by: disposeBag)
  }

  private func reload(with newTrip: [TripSectionVM]) {
    // self.trip = newTrip
    let trip = newTrip.map { LineWithStations(line: $0.line, stations: $0.stationVMs.map { $0.station }) }
    let source = viewedTrip.map { $0.differenceKitSection }
    let target = newTrip.map { $0.differenceKitSection }
    self.tableView?.reload(using: StagedChangeset(source: source, target: target), with: .automatic) { data in
      self.viewedTrip = data.map {
        let stations = $0.elements.map { $0.station }
        return TripSectionVM(line: $0.model.line, stations: stations, in: trip)
      }
    }
    if self.viewedTrip.isNotEmpty {
      self.tableView.scrollToRow(at: .zero, at: .top, animated: true)
    }
  }

  func changeDepartureStation(to newStation: Station) {
    vm.fromStation.accept(newStation)
  }

  func changeDestinationStation(to newStation: Station) {
    vm.toStation.accept(newStation)
  }
}

extension TripVC: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    viewedTrip.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewedTrip[section].stationVMs.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.stationCell, for: indexPath)!
    let vm = viewedTrip[indexPath.section].stationVMs[indexPath.row]
    cell.bind(to: vm)
    return cell
  }
}

extension TripVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let lbl = UILabel()
    lbl.backgroundColor = viewedTrip[section].line.color
    lbl.textColor = .white
    lbl.textAlignment = .center
    lbl.setAutoScaledFont(forTextStyle: .headline)
    let stations = viewedTrip[section].stationVMs
    let isStartToEnd = stations.first!.station.indexInLine! < stations.last!.station.indexInLine!
    let currentLine = allData.first { $0.line.id == viewedTrip[section].line.id }!
    let startTerminalStation = currentLine.stations.first { $0.id == currentLine.line.startTerminalId }!
    let endTerminalStation = currentLine.stations.first { $0.id == currentLine.line.endTerminalId }!
    let terminalStation = isStartToEnd ? endTerminalStation : startTerminalStation
    lbl.text
      = "\(viewedTrip[section].line.localizedName) - \(Localizable.terminalDirection(terminalStation.primaryName))"
    return lbl
  }
}

extension TripVC: ViewController {
  static func instantiate() -> TripVC {
    return mainStoryboard.tripVC()!
  }
}
