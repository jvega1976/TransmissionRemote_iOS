//
//  FileListCell.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//

import UIKit
import NMOutlineView
import TransmissionRPC

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
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var longPressView: UIView!
    
    public var torrentFilesController: TorrentFilesController!
    // Touch recognizer
    var tapRecognizer: UITapGestureRecognizer?
    
    
    override func update(with item: Any) {
        guard let item = item as? FSItem else { return }
        
        self.nameLabel.text = item.name
        self.progressLabel.text = item.downloadProgressString
        self.nameLabel.textColor = UIColor.label
        self.prioritySegment.addTarget(torrentFilesController, action: #selector(torrentFilesController.prioritySegmentToggled(_:)), for: .valueChanged)
        self.prioritySegment.dataObject = item
        self.prioritySegment.isEnabled = true
        self.prioritySegment.selectedSegmentIndex = item.priority.rawValue
         self.checkBox.removeTarget(torrentFilesController, action: #selector(torrentFilesController.toggleDownloading(_:)), for: .valueChanged)
        self.checkBox.addTarget(torrentFilesController, action: #selector(torrentFilesController.toggleDownloading(_:)), for: .valueChanged)
        self.checkBox.isSelected = item.isWanted
        self.checkBox.tintColor = item.isWanted ? self.tintColor : UIColor.secondaryLabel
        self.checkBox.dataObject = item
        if self.longPressView.gestureRecognizers == nil {
            let longPress = UILongPressGestureRecognizer(target: torrentFilesController, action: #selector(torrentFilesController.renameFile(_:)))
            longPress.dataObject = item
            self.longPressView.addGestureRecognizer(longPress)
        } else {
            for gesture in self.longPressView.gestureRecognizers! {
                self.longPressView.removeGestureRecognizer(gesture)
            }
            let longPress = UILongPressGestureRecognizer(target: torrentFilesController, action: #selector(torrentFilesController.renameFile(_:)))
            longPress.dataObject = item
            self.longPressView.addGestureRecognizer(longPress)
        }
        self.longPressView.isUserInteractionEnabled = true
        
        if item.isFile {
            self.fileTypeIcon.image = UIImage(systemName: "doc")
            if torrentFilesController.addingTorrent {
                self.progressBar.isHidden = true
                self.progressLabel.isHidden = true
                self.detailLabel.text = NSLocalizedString("\(item.sizeString)", comment: "FileList cell file info")
            } else {
                self.progressBar.progress = Float(item.downloadProgress)
                self.detailLabel.text = NSLocalizedString("\(item.downloadProgress < 1 ? "Downloading:  " : "Downloaded:  ") \(item.bytesCompletedString) of \(item.sizeString)", comment: "FileList cell file info")
            }
            
            let doubleTapRecognizer = UITapGestureRecognizer(target: torrentFilesController, action: #selector(torrentFilesController.playFile(_:)))
            doubleTapRecognizer.numberOfTapsRequired = 2
            self.contentView.addGestureRecognizer(doubleTapRecognizer)
            self.contentView.isUserInteractionEnabled = true
            if item.isWanted {
                self.prioritySegment.isEnabled = true
            }else {
                self.prioritySegment.isEnabled = false
            }
        } else {
            self.fileTypeIcon.image = UIImage(systemName: "folder.fill")
            if torrentFilesController.addingTorrent {
                self.progressBar.isHidden = true
                self.detailLabel.text = String(format: NSLocalizedString("%i files, %@", comment: ""), item.filesCount, item.sizeString)
            } else {
                self.progressBar.progress = Float(item.downloadProgress)
                self.detailLabel.text = String(format: NSLocalizedString("%i Files, %@:  %@ of %@", comment: ""), item.filesCount, item.downloadProgress < 1 ? "Downloading" : "Downloaded", item.bytesCompletedString, item.sizeString)
            }
            self.toggleButton.contentHorizontalAlignment = .right
        }
    }
    
    
}


