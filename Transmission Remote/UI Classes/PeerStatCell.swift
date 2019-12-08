//
//  PeerStatCell.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//

import UIKit

let CELL_ID_PEERSTAT = "peerStatCell"

@objcMembers
class PeerStatCell: UITableViewCell {
    
    @IBOutlet weak var labelFromCache: UILabel!
    @IBOutlet weak var labelFromDht: UILabel!
    @IBOutlet weak var labelFromPex: UILabel!
    @IBOutlet weak var labelFromLpd: UILabel!
    @IBOutlet weak var labelFromTracker: UILabel!
    @IBOutlet weak var labelFromIncoming: UILabel!
}
