//
//  DockView.swift
//  Transmission Remote
//
//  Created by  on 12/23/19.
//

import Cocoa

public class DockView: NSView {
    @IBOutlet public var contentView: NSView!
    @IBOutlet public var downloadLabel: NSTextField!
    @IBOutlet public var uploadLabel: NSTextField!
    

    
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 128, height: 128))
        commonInit()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)
        addSubview(contentView)
        //self.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = self.bounds
    }
    
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }
    
}
