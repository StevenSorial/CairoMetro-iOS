import DifferenceKit
import RxSwift
import UIKit

final class SelectStationVC: UITableViewController, ObserverClass {

  let disposeBag = DisposeBag()
  private let vm = SelectStationVM()
  private let stationSubject = PublishSubject<Station>()
  private var data: [ListSectionVM] = []

  private var searchController: UISearchController { navigationItem.searchController! }
  private var searchVC: StationSearchVC { searchController.searchResultsController as! StationSearchVC }
  var stationObservable: Observable<Station> { stationSubject.asObservable() }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupBindings()
  }

  private func setupUI() {
    title = Localizable.stations()
    definesPresentationContext = true
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    let searchController = UISearchController(searchResultsController: StationSearchVC.instantiate())
    searchController.obscuresBackgroundDuringPresentation = true
    searchController.hidesNavigationBarDuringPresentation = true
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.searchController = searchController
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag
    tableView.rowHeight = 70
    tableView.sectionHeaderHeight = 35
    tableView.register(R.nib.stationCell)
  }

  func setupBindings() {
    setupTableViewBindings()
    navigationItem.leftBarButtonItem!.rx.tap.bind {
      self.navigationController?.dismiss(animated: true)
    }.disposed(by: disposeBag)

    searchController.searchBar.rx.text.orEmpty
      .bind(to: searchVC.query)
      .disposed(by: disposeBag)

    searchVC.selectionObservable.bind {_, _, station in
      self.navigationController?.dismiss(animated: true)
      self.stationSubject.onNext(station)
    }.disposed(by: disposeBag)
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

    vm.selectIndex.map { index in
      self.data[index.section].stationVMs[index.row].station
    }.bind { item in
      self.dismiss(animated: true)
      self.stationSubject.onNext(item)
    }.disposed(by: disposeBag)
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
}

extension SelectStationVC {

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    data[section].stationVMs.count
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    data.count
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

extension SelectStationVC: ViewController {
  static func instantiate() -> SelectStationVC {
    return SelectStationVC()
  }
}
