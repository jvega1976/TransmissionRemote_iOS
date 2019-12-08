//
//  AddTorrentCell.swift
//  Transmission Remote
//
//  Created by  on 7/31/19.
//

import UIKit

let CELL_ID_CHOOSESERVER = "addTorrentCell"

@objcMembers
class AddTorrentCell: UITableViewCell {
    @IBOutlet weak var labelServerName: UILabel!
    @IBOutlet weak var labelServerUrl: UILabel!
    @IBOutlet weak var iconServer: UIImageView!
}
