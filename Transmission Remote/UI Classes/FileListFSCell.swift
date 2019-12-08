//
//  FileListCell.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//

import UIKit
import NMOutlineView

public let CELL_ID_FILELISTFSCELL = "fileListFSCell"
public let FILELISTFSCELL_LEFTLABEL_WIDTH = 28
public let FILELISTFSCELL_LEFTLABEL_LEVEL_INDENTATION = 15

 @IBDesignable @objcMembers class FileListFSCell: NMOutlineViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var prioritySegment: UISegmentedControl!
    @IBOutlet weak var checkBox: UICheckBox!
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var fileTypeIcon: UIImageView!
    
    @IBOutlet weak var longPressView: UIView!
    
    // Touch recognizer
    var tapRecognizer: UITapGestureRecognizer?
//    var isCollapse: Bool! = false
    
/*    override func awakeFromNib() {
        super.awakeFromNib()
//        self.layoutSubviews()
//        toggleButton.addTarget(self, action: #selector(super.toggleButtonAction(sender:)), for: .touchUpInside)
    }
 */
    
}


