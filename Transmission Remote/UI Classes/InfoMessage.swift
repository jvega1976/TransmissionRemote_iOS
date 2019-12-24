//
//  InfoMessage.swift
//  Transmission Remote
//
//  Created by  on 7/31/19.
//




let INFO_MESSAGE_TOPMARGIN = 0
let INFO_MESSAGE_CORNERRADIUS = 3

let INFO_MESSAGE_DEFAULTHIDETIMEOUT:Double = 2

let INFO_MESSAGE_ICONCHECK = "iconCheck20x20"
let INFO_MESSAGE_ICONEXCLAMATION = "iconExclamation20x20"
let INFO_MESSAGE_BUNDLENAME = "InfoMessage"

import UIKit

@IBDesignable class InfoMessage: UIView {
    
    private var showTimeDelay:Double = 0
    

    @IBOutlet weak public var label: UILabel!
    @IBOutlet weak public var icon: UIImageView!
    
    var iconInfo: UIImage!
    var iconError: UIImage!
    
    let infoMessageIconCheck: UIImage! = UIImage(systemName: "checkmark.circle.fill")
    let infoMessageIconExclamation: UIImage! = UIImage(systemName: "exclamationmark.triangle.fill")
    
    public init(size sz: CGSize) {
        super.init(frame: CGRect(origin: CGPoint.zero, size: sz))
        
        let msg = Bundle.main.loadNibNamed(INFO_MESSAGE_BUNDLENAME, owner: self, options: nil)?.first as! InfoMessage
        msg.frame = CGRect(x: 0, y: 0, width: sz.width, height: sz.height)
        
        msg.iconInfo = infoMessageIconCheck
        msg.iconError = infoMessageIconExclamation
        
        msg.layer.cornerRadius = CGFloat(INFO_MESSAGE_CORNERRADIUS)
        msg.layer.shadowColor = UIColor.black.cgColor
        msg.layer.shadowOpacity = 0.2
        msg.layer.shadowOffset = CGSize(width: 3, height: 3)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.iconInfo = infoMessageIconCheck
        self.iconError = infoMessageIconExclamation
        
        self.layer.cornerRadius = CGFloat(INFO_MESSAGE_CORNERRADIUS)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 3, height: 3)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.iconInfo = infoMessageIconCheck
        self.iconError = infoMessageIconExclamation
        
        self.layer.cornerRadius = CGFloat(INFO_MESSAGE_CORNERRADIUS)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 3, height: 3)
    }
    
    override func awakeFromNib() {
        guard let frame = self.window?.bounds else { return }
        self.frame.size.width = frame.size.width
        self.frame.origin.y = 0
    }
    
    func show(from parentView: UIView?) {
        let p = CGPoint(x: parentView?.center.x ?? 0.0, y: -bounds.size.height / 2)
        
        if let frame = parentView?.bounds {
            self.frame.size.width = frame.size.width
        }
        center = p

        // animiate
        parentView?.addSubview(self)

        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            var pEnd = p
            pEnd.y = self.bounds.size.height / 2 + CGFloat(INFO_MESSAGE_TOPMARGIN)
            self.center = pEnd

        }) { finished in
            // hide message after delay
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(self.showTimeDelay * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {

                UIView.animate(withDuration: 0.1, animations: {
                    self.center = p
                }) { finished in
                    self.removeFromSuperview()
                }

            })
        }
    }

    func showInfo(_ infoStr: String?, from parentView: UIView?) {
        showTimeDelay = INFO_MESSAGE_DEFAULTHIDETIMEOUT
        setText(infoStr)
        self.frame.size.width = parentView?.bounds.width ?? 0.0
        self.frame.origin.y = parentView?.bounds.origin.y ?? 0.0
        label.textColor = UIColor.white
        icon.image = iconInfo
        self.backgroundColor = UIColor.systemGreen
        icon.tintColor = UIColor.white

        show(from: parentView)
    }

    func showErrorInfo(_ errStr: String?, from parentView: UIView?) {
        showTimeDelay = Double(INFO_MESSAGE_DEFAULTHIDETIMEOUT) * 1.3

        setText(errStr)
        self.frame.size.width = parentView?.bounds.width ?? 0.0
        self.frame.origin.y = parentView?.bounds.origin.y ?? 0.0
        label.textColor = UIColor.white
        icon.image = iconError
        self.backgroundColor = UIColor.colorError
        icon.tintColor = UIColor.white

        show(from: parentView)
    }
    
    func showMessage(_ errStr: String?, from parentView: UIView?) {
        showTimeDelay = Double(INFO_MESSAGE_DEFAULTHIDETIMEOUT) * 1.3
        setText(errStr)
        self.frame.size.width = parentView?.bounds.width ?? 0.0
        self.frame.origin.y = parentView?.bounds.origin.y ?? 0.0
        show(from: parentView)
    }


    func setText(_ text: String?) {
        label.text = text
        layoutIfNeeded()

        let sz = label.bounds.size
        if bounds.size.height <= (sz.height - 16) {
            // change window bounds
            var r = bounds
            r.size.height = sz.height + 16
            bounds = r
            setNeedsLayout()
        }
    }
}
