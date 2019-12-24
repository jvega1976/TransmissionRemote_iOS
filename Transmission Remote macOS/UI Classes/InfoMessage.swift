//
//  InfoMessage.swift
//  Transmission Remote
//
//  Created by  on 12/23/19.
//

import Cocoa

fileprivate let infoImage = NSImage(named: "IconInfo25x25")
fileprivate let errorImage = NSImage(named: NSImage.stopProgressFreestandingTemplateName)

public class InfoMessage: NSPopover {
    
    @objc dynamic private var infoController: InfoMessageController {
        get {
            return contentViewController as! InfoMessageController
        }
        set(controller) {
            contentViewController = controller
        }
    }

    override init() {
        super.init()
        infoController = InfoMessageController(nibName: nil, bundle: nil)
        let _ = infoController.view
        behavior = .transient
        animates = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        infoController = InfoMessageController(nibName: nil, bundle: nil)
        let _ = infoController.view
        behavior = .transient
        animates = true
        
    }
    
    class func displayInfoMessage(_ message: String, in parentView: NSView) {
        let infoMessage = InfoMessage()
        infoMessage.infoController.message.stringValue = message
        infoMessage.infoController.message.textColor = .white
        infoMessage.infoController.messageImage.image = infoImage
        infoMessage.infoController.messageImage.contentTintColor = .white
        infoMessage.infoController.contentView.fillColor = NSColor(named: "InfoMessage") ?? .systemGreen
        let anchor = NSRect(x: parentView.frame.size.width / 2.0, y: 30.0, width: 1.0, height: 1.0)
        infoMessage.show(relativeTo: anchor, of: parentView, preferredEdge: .maxY)
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            infoMessage.close()
        }
    }
    
    
    class func displayErrorMessage(_ message: String, in parentView: NSView) {
        let infoMessage = InfoMessage()
        infoMessage.infoController.message.stringValue = message
        infoMessage.infoController.message.textColor = .white
        infoMessage.infoController.messageImage.image = errorImage
        infoMessage.infoController.messageImage.contentTintColor = .white
        infoMessage.infoController.contentView.fillColor = .systemRed
        let anchor = NSRect(x: parentView.frame.size.width / 2.0, y: 30.0, width: 1.0, height: 1.0)
        infoMessage.show(relativeTo: anchor, of: parentView, preferredEdge: .maxY)
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            infoMessage.close()
        }
    }


}
