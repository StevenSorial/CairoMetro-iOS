import SwiftyUserDefaults
import UIKit

@available(iOS 13.0, *)
final class SettingsVC: UITableViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  func setupUI() {
    title = Localizable.settings()
    tableView.alwaysBounceVertical = false
    tableView.register(cellType: SettingsCell.self)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return Setting.allCases.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let section = Setting.allCases[section]
    switch section {
      case .theme: return Localizable.theme()
      default: return nil
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section = Setting.allCases[section]
    switch section {
      case .theme(let themes): return themes.count
      case .language: return 1
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(for: indexPath) as SettingsCell
    let section = Setting.allCases[indexPath.section]
    switch section {
      case .theme(let themes): cell.setupFor(theme: themes[indexPath.row])
      case .language(let langName): cell.setupFor(language: langName)
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    defer { tableView.deselectRow(at: indexPath, animated: true) }
    let section = Setting.allCases[indexPath.section]
    switch section {
      case .theme(let themes):
        Defaults[\.theme] = themes[indexPath.row]
        tableView.reloadData()
      case .language:
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
  }
}

@available(iOS 13.0, *)
extension SettingsVC: ViewController {
  static func instantiate() -> SettingsVC {
    return SettingsVC(style: .insetGrouped)
  }
}
