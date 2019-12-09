//
//  UILabel+Copyable.swift
//  
//
//  Created by  on 12/8/19.
//

import UIKit
import ObjectiveC

extension UILabel {
    
    private static var copyingEnabledKey = 0
    private static var shouldUseLongPressGestureRecognizerKey = 0
    private static var longPressGestureRecognizerKey = 0
    
    @IBInspectable @objc dynamic public var copyingEnabled: Bool {
        get {
            guard let value =  objc_getAssociatedObject(self, &UILabel.copyingEnabledKey) as? Bool else { return false }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UILabel.copyingEnabledKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @IBInspectable @objc dynamic public var shouldUseLongPressGestureRecognizer: Bool {
        get {
            guard let value = objc_getAssociatedObject(self, &UILabel.shouldUseLongPressGestureRecognizerKey) as? Bool else {
                return false
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UILabel.shouldUseLongPressGestureRecognizerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc dynamic private var longPressGestureRecognizer: UILongPressGestureRecognizer? {
        get {
            return objc_getAssociatedObject(self, &UILabel.longPressGestureRecognizerKey) as? UILongPressGestureRecognizer
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UILabel.longPressGestureRecognizerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    private func setupGestureRecognizers()
    {
        // Remove gesture recognizer
        if self.longPressGestureRecognizer != nil {
            self.removeGestureRecognizer(self.longPressGestureRecognizer!)
            self.longPressGestureRecognizer = nil
        }
        
        if self.shouldUseLongPressGestureRecognizer && self.copyingEnabled  {
            self.isUserInteractionEnabled = true
            // Enable gesture recognizer
            self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(getter: longPressGestureRecognizer))
            self.addGestureRecognizer(self.longPressGestureRecognizer!)
        }
    }
    
    override open var canBecomeFirstResponder: Bool
    {
        return self.copyingEnabled;
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
    {
        return (action == #selector(copy(_:)) && self.copyingEnabled)
    }
    
    @objc override open func copy(_ sender: Any?)
    {
        if self.copyingEnabled
        {
    // Copy the label text
            let pasteboard = UIPasteboard.general
            pasteboard.string = self.text
        }
    }
    
    @available(iOS 13.0, *)
    @objc public func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer)
    {
        if gestureRecognizer == self.longPressGestureRecognizer {
            if gestureRecognizer.state == .began {
                self.becomeFirstResponder()
                let copyMenu = UIMenuController.shared
                copyMenu.arrowDirection = .default
                copyMenu.showMenu(from: self, rect: self.bounds)
            }
        }
    }
}
