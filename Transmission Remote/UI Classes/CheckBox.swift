//
//  CheckBox.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//

import UIKit


let CHECKBOX_FILLALPHA:CGFloat = 0.03
let ANIMATION_SCALEFACTOR:CGFloat = 1.3
let DISABLED_COLOR = UIColor.gray
let LAYER_FRAME = CGRect(x: 0, y: 0, width: 22, height: 22)

@IBDesignable class CheckBox: UIControl {
    
    private var layerBox: CAShapeLayer!
    private var layerCheck: CAShapeLayer!
    private var tapRecognizer: UITapGestureRecognizer!
    private var fillColor: UIColor!
    
    
    
    func createLayers() {
        fillColor = color.withAlphaComponent(CGFloat(CHECKBOX_FILLALPHA))
        
        layerBox = CAShapeLayer()
        layerBox.strokeColor = color.cgColor
        //_layerBox.fillColor = [UIColor clearColor].CGColor;
        layerBox.fillColor = fillColor.cgColor
        layerBox.lineCap = .round
        layerBox.lineWidth = 1.0
        layerBox.contentsScale = UIScreen.main.scale
        layerBox.frame = LAYER_FRAME
        
        let rectPath = UIBezierPath(roundedRect: CGRect(x: 1.5, y: 1.5, width: 22, height: 22), cornerRadius: 5)
        
        layerBox.path = rectPath.cgPath
        
        layerCheck = CAShapeLayer()
        layerCheck.strokeColor = color.cgColor
        layerCheck.fillColor = UIColor.clear.cgColor
        layerCheck.lineCap = .round
        layerCheck.lineJoin = .round
        layerCheck.lineWidth = 3.5
        layerCheck.contentsScale = UIScreen.main.scale
        //    _layerCheck.shadowColor = [UIColor blackColor].CGColor;
        //    _layerCheck.shadowOpacity = 0.3;
        //    _layerCheck.shadowOffset = CGSizeMake(1.1, 1.1);
        //    _layerCheck.shadowRadius = 1.0;
        layerCheck.frame = LAYER_FRAME
        
        let checkPath = UIBezierPath()
        checkPath.move(to: CGPoint(x: 7, y: 15))
        checkPath.addLine(to: CGPoint(x: 12.5, y: 19.5))
        checkPath.addLine(to: CGPoint(x: 18.5, y: 7))
        
        layerCheck.path = checkPath.cgPath
        layer.addSublayer(layerBox)
        
        layer.addSublayer(layerCheck)
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleCheckbox))
    
        addGestureRecognizer(tapRecognizer)
    }
    
    var isEnable: Bool = true {
        didSet {
            super.isEnabled = isEnabled
            
            tapRecognizer.isEnabled = self.isEnabled
            
            layerCheck.strokeColor = self.isEnabled ? color.cgColor : color.withAlphaComponent(0.5).cgColor //DISABLED_COLOR.CGColor;
            layerBox.strokeColor = self.isEnabled ? color.cgColor : color.withAlphaComponent(0.5).cgColor //DISABLED_COLOR.CGColor;
            layerBox.fillColor = self.isEnabled ? fillColor.cgColor : color.withAlphaComponent(CGFloat(CHECKBOX_FILLALPHA)).cgColor
        }
    }
    
    
    @IBInspectable @objc var isOn: Bool = false {
        didSet {
            
            if isOn {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.4)
                
                layerCheck.strokeEnd = 1.0
                
                CATransaction.commit()
            } else {
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.1)
                
                layerCheck.strokeStart = 0.5
                layerCheck.strokeEnd = 0.5
                
                CATransaction.commit()
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.0)
                    
                    self.layerCheck.strokeStart = 0.0
                    self.layerCheck.strokeEnd = 0.0
                    
                    CATransaction.commit()
                })
            }
            
            let mtx = CATransform3DMakeScale(ANIMATION_SCALEFACTOR, ANIMATION_SCALEFACTOR, 1.0)
            layerBox.transform = mtx
            layerCheck.transform = mtx
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                self.layerBox.transform = CATransform3DIdentity
                self.layerCheck.transform = CATransform3DIdentity
            })
        }
    }
    
    
    @IBInspectable var color: UIColor! {
        didSet {
            layerCheck.strokeColor = color.cgColor
            layerBox.strokeColor = color.cgColor
            layerBox.fillColor = color.withAlphaComponent(CGFloat(CHECKBOX_FILLALPHA)).cgColor
        }
    }
    
    
    
    @objc func toggleCheckbox() {
        self.setValue(!isOn, forKey: "isOn")
        sendActions(for: .valueChanged)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if color == nil {
            color = tintColor
        }
        
        createLayers()

        //on = on    // Skipping redundant initializing to itself
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        color = tintColor
        
        createLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if color == nil {
            color = tintColor
        }
        createLayers()
    }

}
