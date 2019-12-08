//
//  NMOutlineViewCell.swift
//
//  Created by Greg Kopel on 11/05/2017.
//  Copyright © 2017 Netmedia. All rights reserved.
//

import UIKit

@IBDesignable @objcMembers class NMOutlineViewCell: UITableViewCell {
    
    
    // MARK: Properties
    var value: Any?
    @IBOutlet var toggleButton: UIButton!
    @IBInspectable var isExpanded: Bool = false
    @IBInspectable var isAnimating: Bool = false
    @IBInspectable var buttonExpandedImage: UIImage! = UIImage(systemName: "arrowtriangle.down.fill")
    @IBInspectable var buttonImage: UIImage! = UIImage(systemName: "arrowtriangle.right.fill")
    
    var onToggle: ((NMOutlineViewCell) -> Void)?
    
    
    // MARK: Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Expand/collapse button
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        self.indentationLevel = 0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.toggleButton.addTarget(self, action: #selector(toggleButtonAction(sender:)), for: .touchUpInside)
    }
    
    func commonInit() {
        self.indentationLevel = 0
        self.toggleButton = UIButton(type: .custom)
        self.toggleButton.addTarget(self, action: #selector(toggleButtonAction(sender:)), for: .touchUpInside)
        self.toggleButton.frame = CGRect(x: 8, y: contentView.bounds.height/2 - NMOutlineView.buttonSize.height/2, width: NMOutlineView.buttonSize.width, height: NMOutlineView.buttonSize.height)
//        self.contentView.addSubview(self.toggleButton)
        self.toggleButton.setImage(NMOutlineView.buttonImage, for: .normal)
//        self.toggleButton.tintColor = NMOutlineView.buttonColor
        self.toggleButton.contentVerticalAlignment = .center
        self.toggleButton.contentHorizontalAlignment = .center
    }

    // MARK: Layout
    
   override func layoutSubviews() {
        super.layoutSubviews()
        var indentationX: CGFloat
        if toggleButton.isHidden {
            indentationX = (CGFloat(indentationLevel-1) * indentationWidth)
        } else {
            indentationX = (CGFloat(indentationLevel) * indentationWidth)
        }
        contentView.frame = CGRect(x: indentationX, y: 0, width: bounds.size.width - indentationX, height: bounds.size.height)
    }

    
    
    // MARK: API
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    @objc func toggleButtonAction(sender: UIButton) {
        if let onToggle = self.onToggle {
            onToggle(self)
            updateState(!isExpanded, animated: true)
        }
    }
    
    
    func updateState(_ isExpanded: Bool, animated: Bool) {
        self.isExpanded = isExpanded
        
        // Update toggle button state
        if !toggleButton.isHidden && !isAnimating {
            var image: UIImage
            if isExpanded {
                image = buttonExpandedImage
            } else {
                image = buttonImage
            }
            toggleButton.setImage(image, for: .normal)
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }
}

