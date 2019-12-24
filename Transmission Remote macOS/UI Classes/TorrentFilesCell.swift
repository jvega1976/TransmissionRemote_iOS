//
//  TorrentFilesCell.swift
//  Transmission Remote
//
//  Created by  on 12/30/19.
//

import Cocoa

class TorrentFilesCell: NSTableCellView {
    @IBOutlet weak var isWantedSwitch: NSSwitch!
    
    @IBOutlet weak var nameLabel: NSTextField!
    
    @IBOutlet weak var fileTypeImage: NSImageView!
    
    @IBOutlet weak var downloadProgressBar: NSProgressIndicator!
    
    @IBOutlet weak var prioritySegmentedControl: NSSegmentedControl!
    @IBOutlet weak var detailsLabel: NSTextField!
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @objc dynamic public var isSelected: Bool = false
    
    
}
