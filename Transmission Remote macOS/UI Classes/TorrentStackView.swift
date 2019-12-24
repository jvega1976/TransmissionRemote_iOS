//
//  TorrentStackView.swift
//  Transmission Remote
//
//  Created by  on 12/21/19.
//

import Cocoa

public class TorrentStackView: NSStackView {

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @IBInspectable @objc dynamic override public var isFlipped: Bool {
        return true
    }
    
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
}
