//
//  CategoryCellView.swift
//  Transmission Remote
//
//  Created by  on 12/12/19.
//

import Cocoa

@objc public class CategoryCellView: NSTableCellView {

    @IBOutlet public var title: NSTextField!
    
    @IBOutlet public var icon: IconCloud!
    
    @IBOutlet weak var ItemsCount: NSTextField!
    
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.icon = IconCloud(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.title = NSTextField(string: "")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
