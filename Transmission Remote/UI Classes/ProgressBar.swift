//
//  ProgressBar.swift
//  Transmission Remote
//
//  Created by  on 7/26/19.
//

#if !os(macOS) || targetEnvironment(macCatalyst)
import UIKit

@IBDesignable @objcMembers public class ProgressBar: UIView {
    
    var _progress: CGFloat = 0.0
    @objc dynamic var progressColor: UIColor {
        get {
            return self.tintColor
        }
        set(color) {
            self.tintColor = color
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBInspectable @objc dynamic var progress: Float  {
        set(newProgress) {
            _progress = CGFloat(newProgress)
            self.setNeedsDisplay()
        }
        get {
            return Float(_progress)
        }
    }
    
    override public func draw(_ rect: CGRect) {
        let bar =  UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.size.width * _progress, height: self.frame.size.width))
        progressColor.setFill()
        bar.fill()
    }
    
    class func keyPathsForValuesAffectingProgressColor() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["tintColor"])
    }
}

#else
import Cocoa

@IBDesignable @objcMembers public class ProgressBar: NSView {
    
    @objc dynamic private var _progress: CGFloat = 0.0
    @objc dynamic private var _progressColor: NSColor = .systemBlue
    
    @IBInspectable @objc dynamic public var progressColor: NSColor {
        get {
            return self._progressColor
        }
        set(color) {
            self._progressColor = color
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBInspectable @objc dynamic public var progress: Float  {
        set(newProgress) {
            _progress = CGFloat(newProgress)
            self.display()
        }
        get {
            return Float(_progress)
        }
    }
    
    override public func draw(_ rect: CGRect) {
        NSColor.quaternaryLabelColor.setFill()
        NSBezierPath.fill(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        progressColor.setFill()
        NSBezierPath.fill(CGRect(x: 0, y: 0, width: self.frame.size.width * _progress, height: self.frame.size.height))
        NSColor.tertiaryLabelColor.setStroke()
        NSBezierPath.stroke(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
    }
    
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.draw(self.frame)
    }
}
#endif
