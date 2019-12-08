//
//  ServerListCell.swift
//  Transmission Remote
//
//  Created by  on 7/12/19.
//

import UIKit

class ServerListCell: UITableViewCell {
    
    @IBOutlet weak var serverName: UILabel!
    @IBOutlet weak var serverURL: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
