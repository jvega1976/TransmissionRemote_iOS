//
//  TrackerListCellTableViewCell.swift
//  Transmission Remote
//
//  Created by  on 7/27/19.
//

import UIKit

let CELL_ID_TRACKERINFO = "trackerListCell"

@objcMembers
class TrackerListCell: UITableViewCell {
    var trackerId = 0
    @IBOutlet weak var trackerHostLabel: UILabel!
    @IBOutlet weak var lastAnnounceTimeLabel: UILabel!
    @IBOutlet weak var nextAnnounceTimeLabel: UILabel!
    @IBOutlet weak var lastScrapeTimeLabel: UILabel!
    @IBOutlet weak var nextScrapeTimeLabel: UILabel!
    @IBOutlet weak var seedersLabel: UILabel!
    @IBOutlet weak var leechersLabel: UILabel!
    @IBOutlet weak var downloadsLabel: UILabel!
    @IBOutlet weak var peersLabel: UILabel!
}
