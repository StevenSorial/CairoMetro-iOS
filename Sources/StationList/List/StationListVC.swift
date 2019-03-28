import CoreLocation
import DifferenceKit
import MapKit
import RxSwift
import UIKit

final class StationListVC: UITableViewController, ObserverClass {

  let disposeBag = DisposeBag()
  private let vm = StationListVM()
  var data: [ListSectionVM] = []
  private var searchController: UISearchController { navigationItem.searchController! }
  private var searchVC: StationSearchVC { searchController.searchResultsController as! StationSearchVC }
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupBindings()
  }

  private func setupUI() {
    title = Localizable.stations()
    definesPresentationContext = true
    navigationItem.rightBarButtonItem = UIBarButtonItem()
    let searchController = UISearchController(searchResultsController: StationSearchVC.instantiate())
    searchController.obscuresBackgroundDuringPresentation = true
    searchController.hidesNavigationBarDuringPresentation = true
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.searchController = searchController
    tableView.separatorStyle = .none
    tableView.rowHeight = 70
    tableView.keyboardDismissMode = .onDrag
    tableView.sectionHeaderHeight = 35
    tableView.register(R.nib.stationCell)
  }

  func setupBindings() {

    setupTableViewBindings()

    navigationItem
    .rightBarButtonItem!.rx.tap
    .bind(to: vm.nearestTappedObserver)
    .disposed(by: disposeBag)

    vm.selectIndex
      .subscribe(onNext: { index in
        let station = self.data[index.section].stationVMs[index.row].station
        self.openActionSheet(in: self.tableView, at: index, with: station)
      }).disposed(by: disposeBag)

    searchVC.selectionObservable.bind { tableView, index, station in
      self.openActionSheet(in: tableView, at: index, with: station)
    }.disposed(by: disposeBag)

    vm.locationBtnStatus
      .subscribe(onNext: updateButtonStatus)
      .disposed(by: disposeBag)

    searchController.searchBar.rx.text.orEmpty
      .bind(to: searchVC.query)
      .disposed(by: disposeBag)

    vm.nearestStation.subscribe(onNext: { nearestStation in
      var stationIndexPath = IndexPath(row: 0, section: 0)
      outer: for (sectionIndex, section) in self.data.enumerated() {
        for (stationIndex, stationVM) in section.stationVMs.enumerated()
          where stationVM.station.id == nearestStation.id {
            stationIndexPath = IndexPath(row: stationIndex, section: sectionIndex)
            break outer
        }
      }
      self.tableView.scrollToRow(at: stationIndexPath, at: .middle, animated: false)
      (self.tableView.cellForRow(at: stationIndexPath) as! StationCell).blink()
    }).disposed(by: disposeBag)
  }

  private func setupTableViewBindings() {
    tableView.rx
      .itemSelected
      .bind(to: vm.selectIndex)
      .disposed(by: disposeBag)

    vm.linesWithStations
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: {
        self.reload(with: $0)
      }).disposed(by: disposeBag)
  }

  private func reload(with newData: [ListSectionVM]) {
    let source = data.map { $0.differenceKitSection }
    let target = newData.map { $0.differenceKitSection }
    tableView.reload(
      using: StagedChangeset(source: source, target: target),
      with: .automatic) {
        self.data = $0.map { ListSectionVM(line: $0.model.line, stations: $0.elements.map { $0.station }) }
    }
  }

  private func updateButtonStatus(to status: StationListVM.LocationBtnStatus) {
    let item = navigationItem.rightBarButtonItem!
    if status == .disabled || status == .normal {
      item.customView = nil
      item.image = R.image.location()!
    } else if status == .loading && !(item.customView is UIActivityIndicatorView) {
      let activity = with(UIActivityIndicatorView()) {
        $0.widthAnchor.constraint(equalToConstant: 28).isActive = true
        $0.heightAnchor.constraint(equalToConstant: 28).isActive = true
        $0.color = .systemGray
        $0.startAnimating()
      }
      item.image = nil
      item.customView = activity
    }
    item.isEnabled = status == .normal
    navigationController?.navigationBar.setNeedsLayout()
  }
}

extension StationListVC {
  override func numberOfSections(in tableView: UITableView) -> Int {
    data.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    data[section].stationVMs.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.stationCell, for: indexPath)!
    let section = data[indexPath.section]
    let vm = section.stationVMs[indexPath.row]
    cell.bind(to: vm)
    return cell
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let lbl = UILabel()
    let line = data[section].line
    lbl.backgroundColor = line.color
    lbl.textColor = .white
    lbl.textAlignment = .center
    lbl.setAutoScaledFont(forTextStyle: .headline)
    lbl.text = line.localizedName
    return lbl
  }
}

extension StationListVC {
  func openActionSheet(in tableView: UITableView, at index: IndexPath, with station: Station) {
    let cell = tableView.cellForRow(at: index)!
    let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alertVC.addAction(UIAlertAction(title: Localizable.startTrip(), style: .default) { [weak self] _ in
      self?.tableView.deselectRow(at: index, animated: true)
      guard let self = self else { return }
      let vc: TripVC! = self.tabBarController?.viewControllers?
        .compactMap { $0 as? AdBannerVC<UIViewController> }
        .compactMap { $0.hostedVC as? UINavigationController }
        .compactMap { $0.viewControllers.first as? TripVC }.first
      self.tabBarController!.selectedIndex = 1
      vc.changeDepartureStation(to: station)
      self.tabBarController!.selectedIndex = 1
    })
    alertVC.addAction(UIAlertAction(title: Localizable.showMap(), style: .default) {[weak self] _ in
      self?.tableView.deselectRow(at: index, animated: true)
      self?.openMapForStation(station: station)
    })
    alertVC.addAction(UIAlertAction(title: Localizable.cancel(), style: .cancel) { [weak self] _ in
      self?.tableView.deselectRow(at: index, animated: true)
    })
    alertVC.popoverPresentationController?.sourceView = cell
    alertVC.popoverPresentationController?.sourceRect = cell.bounds
    alertVC.popoverPresentationController?.permittedArrowDirections = [.up, .down]
    present(alertVC, animated: true)
  }

  func openMapForStation(station: Station) {
    let location = station.location
    if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
      let url = URL(string: "comgooglemaps://?q=\(location.coordinatesByCommas)&zoom=14")!
      UIApplication.shared.open(url)
    } else {
      let placemark = MKPlacemark(coordinate: location.coordinate)
      let mapItem = MKMapItem(placemark: placemark)
      mapItem.name = station.primaryName
      mapItem.openInMaps()
    }
  }
}

extension StationListVC: ViewController {
  static func instantiate() -> StationListVC {
    return StationListVC()
  }
}
