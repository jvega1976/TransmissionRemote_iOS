//
//  InfoMessageController.swift
//  Transmission Remote
//
//  Created by  on 12/23/19.
//

import Cocoa

public class InfoMessageController: NSViewController {

    @IBOutlet public var message: NSTextField!
    @IBOutlet public var messageImage: NSImageView!
    @IBOutlet public var contentView: NSBox!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
