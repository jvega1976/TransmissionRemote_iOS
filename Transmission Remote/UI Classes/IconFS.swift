//
//  IconFS.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//



enum IconFSType : Int {
    case file
    case fileFinished
    case folderClosed
    case folderOpened
    case none
}

#if os(iOS)
import UIKit
@objcMembers
class IconFS: UIView {
    
    var iconType: IconFSType!
    
    private var layerOut: CAShapeLayer!
    private var layerIn: CAShapeLayer!
    private var layerOval: CAShapeLayer!
    private var layerCheck: CAShapeLayer!
    private var layerFolderOut: CAShapeLayer!
    private var layerFolderCheck: CAShapeLayer!
    private var _frame = CGRect.zero
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupValues()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupValues()
    }
    
    
    func setupValues() {
        createLayers()
        setStrokeColors()
    }
    
    
    func createLayers() {
        //NSLog( @"%p - %s", self, __PRETTY_FUNCTION__ );
        
        frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        
        layerOut = CAShapeLayer()
        layerIn = CAShapeLayer()
        layerOval = CAShapeLayer()
        layerCheck = CAShapeLayer()
        
        layerFolderOut = CAShapeLayer()
        layerFolderCheck = CAShapeLayer()
        
        layerCheck.contentsScale = UIScreen.main.scale
        layerOval.contentsScale = layerCheck.contentsScale
        layerIn.contentsScale = layerOval.contentsScale
        layerOut.contentsScale = layerIn.contentsScale
        layerFolderOut.contentsScale = layerOut.contentsScale
        layerFolderCheck.contentsScale = layerFolderOut.contentsScale
        
        layerIn.frame = frame
        layerOut.frame = layerIn.frame
        
        layerOut.lineWidth = 1.5
        layerIn.lineWidth = 2.0
        
        layerOval.lineWidth = 1.5
        layerCheck.lineWidth = 2.0
        
        layerFolderOut.lineWidth = 1.5
        layerFolderCheck.lineWidth = 1.5
        
        layerOut.lineJoin = .round
        layerOut.path = outPath()
        
        layerIn.lineCap = .butt
        layerIn.path = inPath()
        
        layerOval.path = ovalPath()
        
        layerCheck.lineCap = .square
        layerCheck.path = checkPath()
        layerCheck.strokeEnd = 0
        
        layerFolderOut.path = folderOutPath()
        layerFolderCheck.path = folderCheckPath()
        
        if let layerFolderOut = layerFolderOut {
            layer.addSublayer(layerFolderOut)
        }
        
        if let layerOut = layerOut {
            layer.addSublayer(layerOut)
        }
        if let layerIn = layerIn {
            layer.addSublayer(layerIn)
        }
        
        if let layerOval = layerOval {
            layerIn.addSublayer(layerOval)
        }
        if let layerCheck = layerCheck {
            layerIn.addSublayer(layerCheck)
        }
        
        if let layerFolderCheck = layerFolderCheck {
            layerFolderOut.addSublayer(layerFolderCheck)
        }
    }
    
    
    override var tintColor: UIColor! {
        set(newColor) {
            super.tintColor = newColor
            setStrokeColors()
        }
        get {
            return super.tintColor
        }
    }
    
    
    func setStrokeColors() {
        layerOut.fillColor = UIColor.clear.cgColor
        layerOut.strokeColor = tintColor.cgColor
        layerIn.strokeColor = tintColor.cgColor
        layerOval.fillColor = UIColor.white.cgColor
        layerOval.strokeColor = tintColor.cgColor
        layerCheck.fillColor = UIColor.clear.cgColor
        layerCheck.strokeColor = tintColor.cgColor
        layerFolderCheck.strokeColor = tintColor.cgColor
        layerFolderCheck.fillColor = UIColor.clear.cgColor
        layerFolderOut.fillColor = UIColor.clear.cgColor
        layerFolderOut.strokeColor = tintColor.cgColor
    }
    
    
    func setIconType(_ iconType: IconFSType) {
        if self.iconType == iconType {
            return
        }
        
        self.iconType = iconType
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        
        layerIn.isHidden = true
        layerOut.isHidden = true
        layerOval.isHidden = true
        layerCheck.isHidden = true
        layerFolderOut.isHidden = true
        layerFolderCheck.isHidden = true
        
        layerIn.strokeEnd = 1.0
        
        layerFolderOut.transform = CATransform3DIdentity
        layerFolderCheck.transform = layerFolderOut.transform
        layerCheck.transform = layerFolderCheck.transform
        layerOval.transform = layerCheck.transform
        layerOut.transform = layerOval.transform
        layerIn.transform = layerOut.transform
        
        switch iconType {
            case .file:
                layerIn.isHidden = false
                layerOut.isHidden = false
                layerCheck.strokeEnd = 0
                layerCheck.strokeStart = 0
            case .fileFinished:
                layerIn.isHidden = false
                layerOut.isHidden = false
                layerOval.isHidden = false
                layerCheck.isHidden = false
                layerCheck.strokeEnd = 1.0
            case .folderClosed:
                layerFolderOut.isHidden = false
                layerFolderCheck.isHidden = false
            case .folderOpened:
                layerFolderOut.isHidden = false
                layerFolderCheck.isHidden = false
                layerFolderCheck.transform = CATransform3DMakeRotation(90 * .pi / 180.0, 0, 0, 1)
            default:
                break
        }
        
        CATransaction.commit()
    }
    
    
    private var _downloadProgress: CGFloat = 0.0
    
    var downloadProgress: CGFloat {
        set(newProgress) {
            _downloadProgress = newProgress
            layerIn.strokeEnd = _downloadProgress
        }
        get {
            return _downloadProgress
        }
    }
    
    
    func outPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        if path == nil {
            let w = frame.size.width
            let h = frame.size.height
            
            let outsidePath = UIBezierPath()
            outsidePath.move(to: CGPoint(x: 0.09215 * w, y: 0.99074 * h))
            outsidePath.addLine(to: CGPoint(x: 0.09215 * w, y: 0.01049 * h))
            outsidePath.addLine(to: CGPoint(x: 0.58786 * w, y: 0.01049 * h))
            outsidePath.addLine(to: CGPoint(x: 0.91049 * w, y: 0.18483 * h))
            outsidePath.addLine(to: CGPoint(x: 0.91049 * w, y: 0.99074 * h))
            outsidePath.addLine(to: CGPoint(x: 0.09215 * w, y: 0.99074 * h))
            outsidePath.close()
            outsidePath.move(to: CGPoint(x: 0.58786 * w, y: 0.01049 * h))
            outsidePath.addLine(to: CGPoint(x: 0.65623 * w, y: 0.25720 * h))
            outsidePath.addLine(to: CGPoint(x: 0.91049 * w, y: 0.18483 * h))
            path = outsidePath.cgPath
        }
        
        return path
    }
    
    
    func inPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        if path == nil {
            let w = frame.size.width
            let h = frame.size.height
            
            let insidePath = UIBezierPath()
            insidePath.move(to: CGPoint(x: 0.28306 * w, y: 0.46158 * h))
            insidePath.addLine(to: CGPoint(x: 0.44856 * w, y: 0.46158 * h))
            insidePath.move(to: CGPoint(x: 0.28306 * w, y: 0.55698 * h))
            insidePath.addLine(to: CGPoint(x: 0.44856 * w, y: 0.55698 * h))
            insidePath.move(to: CGPoint(x: 0.28306 * w, y: 0.64908 * h))
            insidePath.addLine(to: CGPoint(x: 0.44856 * w, y: 0.64908 * h))
            insidePath.move(to: CGPoint(x: 0.28306 * w, y: 0.74447 * h))
            insidePath.addLine(to: CGPoint(x: 0.44856 * w, y: 0.74447 * h))
            insidePath.move(to: CGPoint(x: 0.28306 * w, y: 0.83658 * h))
            insidePath.addLine(to: CGPoint(x: 0.44856 * w, y: 0.83658 * h))
            insidePath.move(to: CGPoint(x: 0.52469 * w, y: 0.46158 * h))
            insidePath.addLine(to: CGPoint(x: 0.69018 * w, y: 0.46158 * h))
            insidePath.move(to: CGPoint(x: 0.52469 * w, y: 0.55698 * h))
            insidePath.addLine(to: CGPoint(x: 0.69018 * w, y: 0.55698 * h))
            insidePath.move(to: CGPoint(x: 0.52469 * w, y: 0.64908 * h))
            insidePath.addLine(to: CGPoint(x: 0.69018 * w, y: 0.64908 * h))
            insidePath.move(to: CGPoint(x: 0.52469 * w, y: 0.74447 * h))
            insidePath.addLine(to: CGPoint(x: 0.69018 * w, y: 0.74447 * h))
            insidePath.move(to: CGPoint(x: 0.52469 * w, y: 0.83658 * h))
            insidePath.addLine(to: CGPoint(x: 0.69018 * w, y: 0.83658 * h))
            path = insidePath.cgPath
        }
        
        return path
    }
    
    
    func ovalPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        var w = frame.size.width
        var h = frame.size.height
        
        let frame2 = CGRect(x: floor(w * 0.62727 + 0.5), y: floor(h * 0.36364 + 0.5), width: floor(w * 1.00000 + 0.5) - floor(w * 0.52727 + 0.5), height: floor(h * 0.83636 + 0.5) - floor(h * 0.36364 + 0.5))
        
        layerOval.frame = frame2
        
        if path == nil {
            w = frame2.size.width
            h = frame2.size.height
            
            let ovalPath = UIBezierPath(ovalIn: CGRect(x: floor(w * 0.05769) + 0.5, y: floor(h * 0.05769 + 0.5), width: floor(w * 0.96154 + 0.5) - floor(w * 0.05769) - 0.5, height: floor(h * 0.96154) - floor(h * 0.05769 + 0.5) + 0.5))
            
            path = ovalPath.cgPath
        }
        
        return path
    }
    
    
    func checkPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        var w = frame.size.width
        var h = frame.size.height
        
        let frame2 = CGRect(x: floor(w * 0.62727 + 0.5), y: floor(h * 0.36364 + 0.5), width: floor(w * 1.00000 + 0.5) - floor(w * 0.52727 + 0.5), height: floor(h * 0.83636 + 0.5) - floor(h * 0.36364 + 0.5))
        
        layerCheck.frame = frame2
        
        if path == nil {
            w = frame2.size.width
            h = frame2.size.height
            
            let checkPath = UIBezierPath()
            checkPath.move(to: CGPoint(x: 0.30435 * w, y: 0.60870 * h))
            checkPath.addLine(to: CGPoint(x: 0.52539 * w, y: 0.75528 * h))
            checkPath.addLine(to: CGPoint(x: 0.75701 * w, y: 0.28871 * h))
            
            path = checkPath.cgPath
        }
        
        return path
    }
    
    
    func folderCheckPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        var w = frame.size.width
        var h = frame.size.height
        
        let frame2 = CGRect(x: floor(w * 0.75510 + 0.5), y: floor(h * 0.41969 + 0.5), width: floor(w * 1.08163 + 0.5) - floor(w * 0.75510 + 0.5), height: floor(h * 0.75130 + 0.5) - floor(h * 0.41969 + 0.5))
        
        layerFolderCheck.frame = frame2
        
        if path == nil {
            w = frame2.size.width
            h = frame2.size.height
            
            let checkPath = UIBezierPath()
            checkPath.move(to: CGPoint(x: 0.96364 * w, y: 0.50000 * h))
            checkPath.addCurve(to: CGPoint(x: 0.50000 * w, y: 0.03636 * h), controlPoint1: CGPoint(x: 0.96364 * w, y: 0.24394 * h), controlPoint2: CGPoint(x: 0.75606 * w, y: 0.03636 * h))
            checkPath.addCurve(to: CGPoint(x: 0.03636 * w, y: 0.50000 * h), controlPoint1: CGPoint(x: 0.24394 * w, y: 0.03636 * h), controlPoint2: CGPoint(x: 0.03636 * w, y: 0.24394 * h))
            checkPath.addCurve(to: CGPoint(x: 0.50000 * w, y: 0.96364 * h), controlPoint1: CGPoint(x: 0.03636 * w, y: 0.75606 * h), controlPoint2: CGPoint(x: 0.24394 * w, y: 0.96364 * h))
            checkPath.addCurve(to: CGPoint(x: 0.96364 * w, y: 0.50000 * h), controlPoint1: CGPoint(x: 0.75606 * w, y: 0.96364 * h), controlPoint2: CGPoint(x: 0.96364 * w, y: 0.75606 * h))
            checkPath.close()
            checkPath.move(to: CGPoint(x: 0.42845 * w, y: 0.75336 * h))
            checkPath.addLine(to: CGPoint(x: 0.67273 * w, y: 0.50909 * h))
            checkPath.addLine(to: CGPoint(x: 0.42845 * w, y: 0.26482 * h))
            
            path = checkPath.cgPath
        }
        
        return path
    }
    
    
    func folderOutPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        let w = frame.size.width
        let h = frame.size.height
        layerFolderOut.frame = CGRect(x: 0, y: 0, width: w, height: h)
        
        if path == nil {
            let folderPath = UIBezierPath()
            folderPath.move(to: CGPoint(x: 0.98728 * w, y: 0.41008 * h))
            folderPath.addLine(to: CGPoint(x: 0.98732 * w, y: 0.32052 * h))
            folderPath.addLine(to: CGPoint(x: 0.98738 * w, y: 0.20008 * h))
            folderPath.addCurve(to: CGPoint(x: 0.97036 * w, y: 0.15915 * h), controlPoint1: CGPoint(x: 0.98739 * w, y: 0.18464 * h), controlPoint2: CGPoint(x: 0.98171 * w, y: 0.17113 * h))
            folderPath.addCurve(to: CGPoint(x: 0.92836 * w, y: 0.14176 * h), controlPoint1: CGPoint(x: 0.95901 * w, y: 0.14757 * h), controlPoint2: CGPoint(x: 0.94501 * w, y: 0.14177 * h))
            folderPath.addLine(to: CGPoint(x: 0.36478 * w, y: 0.14150 * h))
            folderPath.addCurve(to: CGPoint(x: 0.35155 * w, y: 0.11911 * h), controlPoint1: CGPoint(x: 0.36365 * w, y: 0.14034 * h), controlPoint2: CGPoint(x: 0.35911 * w, y: 0.13262 * h))
            folderPath.addCurve(to: CGPoint(x: 0.32318 * w, y: 0.08011 * h), controlPoint1: CGPoint(x: 0.34398 * w, y: 0.10559 * h), controlPoint2: CGPoint(x: 0.33452 * w, y: 0.09246 * h))
            folderPath.addCurve(to: CGPoint(x: 0.28496 * w, y: 0.06156 * h), controlPoint1: CGPoint(x: 0.31183 * w, y: 0.06775 * h), controlPoint2: CGPoint(x: 0.29896 * w, y: 0.06157 * h))
            folderPath.addLine(to: CGPoint(x: 0.07149 * w, y: 0.06146 * h))
            folderPath.addCurve(to: CGPoint(x: 0.02946 * w, y: 0.07881 * h), controlPoint1: CGPoint(x: 0.05483 * w, y: 0.06145 * h), controlPoint2: CGPoint(x: 0.04120 * w, y: 0.06724 * h))
            folderPath.addCurve(to: CGPoint(x: 0.01241 * w, y: 0.11972 * h), controlPoint1: CGPoint(x: 0.01810 * w, y: 0.09039 * h), controlPoint2: CGPoint(x: 0.01242 * w, y: 0.10390 * h))
            folderPath.addLine(to: CGPoint(x: 0.01232 * w, y: 0.31968 * h))
            folderPath.addLine(to: CGPoint(x: 0.01223 * w, y: 0.53702 * h))
            folderPath.addLine(to: CGPoint(x: 0.01208 * w, y: 0.87672 * h))
            folderPath.addCurve(to: CGPoint(x: 0.02909 * w, y: 0.91764 * h), controlPoint1: CGPoint(x: 0.01207 * w, y: 0.89216 * h), controlPoint2: CGPoint(x: 0.01774 * w, y: 0.90567 * h))
            folderPath.addCurve(to: CGPoint(x: 0.07109 * w, y: 0.93504 * h), controlPoint1: CGPoint(x: 0.04044 * w, y: 0.92923 * h), controlPoint2: CGPoint(x: 0.05444 * w, y: 0.93503 * h))
            folderPath.addLine(to: CGPoint(x: 0.92800 * w, y: 0.93543 * h))
            folderPath.addCurve(to: CGPoint(x: 0.97003 * w, y: 0.91808 * h), controlPoint1: CGPoint(x: 0.94466 * w, y: 0.93544 * h), controlPoint2: CGPoint(x: 0.95829 * w, y: 0.92965 * h))
            folderPath.addCurve(to: CGPoint(x: 0.98708 * w, y: 0.87717 * h), controlPoint1: CGPoint(x: 0.98176 * w, y: 0.90650 * h), controlPoint2: CGPoint(x: 0.98707 * w, y: 0.89300 * h))
            folderPath.addLine(to: CGPoint(x: 0.98713 * w, y: 0.75711 * h))
            folderPath.move(to: CGPoint(x: 0.01271 * w, y: 0.30695 * h))
            folderPath.addCurve(to: CGPoint(x: 0.98544 * w, y: 0.30739 * h), controlPoint1: CGPoint(x: 0.98547 * w, y: 0.30739 * h), controlPoint2: CGPoint(x: 0.98544 * w, y: 0.30739 * h))
            
            path = folderPath.cgPath
        }
        
        return path
    }
    
    
    func playCheckFinishAnimation() {
        layerCheck.isHidden = false
        layerOval.isHidden = false
        
        CATransaction.begin()
        
        CATransaction.setCompletionBlock({
            self.layerOut.transform = CATransform3DIdentity
            self.layerIn.transform = CATransform3DIdentity
            self.layerOval.transform = CATransform3DIdentity
            self.layerCheck.transform = CATransform3DIdentity
        })
        
        CATransaction.setAnimationDuration(1.3)
        
        let mtx = CATransform3DMakeScale(1.15, 1.15, 1.0)
        
        layerOut.transform = mtx
        layerIn.transform = mtx
        layerOval.transform = mtx
        layerCheck.transform = mtx
        layerCheck.strokeEnd = 1.0
        
        CATransaction.commit()
        iconType = IconFSType.fileFinished
    }
    
    
    func playFolderCloseAnimation() {
        rotateFolderCheck(toAngle: 0)
        iconType = IconFSType.folderClosed
    }
    
    
    func playFolderOpenAnimation() {
        rotateFolderCheck(toAngle: 90)
        iconType = IconFSType.folderOpened
    }
    
    
    func rotateFolderCheck(toAngle angleDegrees: CGFloat) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        
        CATransaction.setCompletionBlock({
            self.layerFolderOut.transform = CATransform3DIdentity
        })
        
        layerFolderOut.transform = CATransform3DMakeScale(1.1, 1.1, 1)
        layerFolderCheck.transform = CATransform3DMakeRotation((angleDegrees * .pi) / 180.0, 0, 0, 1)
        
        CATransaction.commit()
    }
}
#endif
