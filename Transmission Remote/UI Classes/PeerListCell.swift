//
//  PeerListCell.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//

import UIKit

let CELL_ID_PEERLISTCELL = "peerListCell"
let CELL_ID_PEERLISTHEADERCELL = "peerListHeaderCell"

@objcMembers
class PeerListCell: UITableViewCell {
    
    @IBOutlet weak var clientLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var iconSecurity: UIImageView!
    @IBOutlet weak var iconUTP: UIImageView!
    @IBOutlet weak var countryName: UILabel!
    @IBOutlet var countryFlagImage: UIImageView!
    
    private var _isSecure = false
    var isSecure: Bool {
        get {
            return _isSecure
        }
        set(isSecure) {
            _isSecure = isSecure
            
            if isSecure {
                iconSecurity.image = UIImage(named: "iconLockLocked15x15")
            } else {
                iconSecurity.image = UIImage(named: "iconLockUnlocked15x15")
            }
        }
    }
    
    
    private var _isUTPEnabled = false
    var isUTPEnabled: Bool {
        get {
            return _isUTPEnabled
        }
        set(isUTPEnabled) {
            _isUTPEnabled = isUTPEnabled
            
            if isUTPEnabled {
                iconUTP.isHidden = false
                iconUTP.image = UIImage(named: "iconUTP15x15")
            } else {
                iconUTP.isHidden = true
            }
        }
    }
}
