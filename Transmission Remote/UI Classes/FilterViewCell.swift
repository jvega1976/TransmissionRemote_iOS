//
//  FilterViewCell.swift
//  Transmission Remote
//
//  Created by  on 11/10/19.
//

import UIKit

class FilterViewCell: UITableViewCell {

    @IBOutlet weak var iconCategory: IconCloud!
    @IBOutlet weak var labelCategory: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
