//
//  SettingsCell.swift
//  CairoMetro
//
//  Created by Steven on 1/17/20.
//  Copyright © 2020 Steven. All rights reserved.
//

import UIKit

class SettingsCell: UITableViewCell, Reusable {

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    tintColor = ColorCompat.metroRed
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupFor(language: String) {
    accessoryType = .disclosureIndicator
    detailTextLabel!.text = language
    textLabel!.text = Localizable.language()
  }

  func setupFor(theme: Theme) {
    accessoryType = theme.isCurrent ? .checkmark : .none
    detailTextLabel!.text = ""
    textLabel!.text = theme.title
   }
}
