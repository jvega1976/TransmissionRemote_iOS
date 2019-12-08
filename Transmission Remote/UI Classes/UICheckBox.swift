//
//  UICheckBox.swift
//  Transmission Remote
//
//  Created by  on 11/5/19.
//

import UIKit

@IBDesignable @objcMembers class UICheckBox: UIButton {
    
    private var tapRecognizer: UITapGestureRecognizer!

    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.setImage(selectedImage, for: .selected)
            }
            else {
                self.setImage(unselectedImage, for: .normal)
            }
        }
    }
    
    
    ///Image Off
    @IBInspectable var unselectedImage: UIImage = UIImage(systemName: "square")!
        
    ///Image On
    @IBInspectable var selectedImage: UIImage = UIImage(systemName: "checkmark.square")!
    
    private var observer: NSKeyValueObservation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.observer = self.observe(\.self.state,changeHandler: { check,change in
            if self.isSelected {
                self.setImage(self.selectedImage, for: .selected)
            }
            else {
                self.setImage(self.unselectedImage, for: .normal)
            }
        })
        self.contentVerticalAlignment = .fill
        self.contentHorizontalAlignment = .fill
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleCheckbox))
        self.addGestureRecognizer(tapRecognizer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.observer = self.observe(\.self.state,changeHandler: { check,change in
            if self.isSelected {
                self.setImage(self.selectedImage, for: .selected)
            }
            else {
                self.setImage(self.unselectedImage, for: .normal)
            }
        })
        self.contentVerticalAlignment = .fill
        self.contentHorizontalAlignment = .fill
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleCheckbox))
        self.addGestureRecognizer(tapRecognizer)
    }
    
     @objc private func toggleCheckbox() {
        self.isSelected = !self.isSelected
        self.sendActions(for: .valueChanged)
    }
    
    
    class func keyPathsForValuesAffectingisSelected() -> Set<String> {
        return Set<String>(["state"])
    }
}
