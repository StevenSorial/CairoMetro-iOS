import DifferenceKit
import RxSwift
import UIKit

final class StationSearchVC: UITableViewController, ObserverClass {

  let disposeBag = DisposeBag()
  private let vm = StationSearchVM()
  private var results: [StationCellVM] = []

  private let selectionSubject = PublishSubject<(UITableView, IndexPath, Station)>()

  var selectionObservable: Observable<(UITableView, IndexPath, Station)> { selectionSubject.asObservable() }
  var query: AnyObserver<String>! { vm.query }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupBindings()
  }

  private func setupUI() {
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag
    tableView.rowHeight = 70
    tableView.sectionHeaderHeight = 0
    tableView.register(R.nib.stationCell)
  }

  func setupBindings() {
    vm.searchResult.subscribe(onNext: {
      self.reload(with: $0)
    }).disposed(by: disposeBag)

    tableView.rx
      .itemSelected
      .bind(to: vm.selectIndex)
      .disposed(by: disposeBag)

    vm.selectIndex
      .bind { index in
        let stationVM = self.results[index.row]
        self.selectionSubject.onNext((self.tableView, index, stationVM.station))
      }.disposed(by: disposeBag)
  }

  private func reload(with newData: [StationCellVM]) {
    tableView.reload(
      using: StagedChangeset(source: results, target: newData),
      with: .automatic) {
        self.results = $0
    }
  }
}

extension StationSearchVC {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     results.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.stationCell, for: indexPath)!
    cell.bind(to: results[indexPath.row])
    return cell
  }
}

extension StationSearchVC: ViewController {
  static func instantiate() -> StationSearchVC {
    return StationSearchVC()
  }
}
