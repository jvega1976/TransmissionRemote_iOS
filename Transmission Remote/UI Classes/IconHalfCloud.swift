//
//  IconHalfCloud.h
//  IconTestApp
//
//  Created by Alexey Chechetkin on 19.08.15.
//  Copyright (c) 2015 Alexey Chechetkin. All rights reserved.
//

@objc enum IconHalfCloudType : Int, Codable {
    case upload
    case download
    case none
    
    func stringValue() -> String {
        switch self {
            case .upload: return "Upload"
            case .download: return "Download"
            case .none: return "None"
        }
    }
    
    init(stringVal string: String) {
        switch string {
            case "Upload": self = .upload
            case "Download": self = .download
            default: self = .none
        }
    }
}


#if os(macOS)

import Cocoa

@IBDesignable @objcMembers
class IconHalfCloud: NSView {
    private var layerCloud: CAShapeLayer?
    private var layerArrowUp: CAShapeLayer?
    private var layerArrowDown: CAShapeLayer?
    private var _frame: CGRect!
    
    private var _iconType: IconHalfCloudType!
    var iconType: IconHalfCloudType! {
        get {
            return _iconType
        }
        set(iconType) {
            _iconType = iconType
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            
            layerArrowDown?.isHidden = true
            layerArrowUp?.isHidden = true
            
            switch iconType {
                case .download:
                    layerArrowDown?.isHidden = false
                case .upload:
                    layerArrowUp?.isHidden = false
                default:
                    break
            }
            
            CATransaction.commit()
            updateLayer()
        }
        
    }
    
    @IBInspectable @objc dynamic var typeString: String {
        get {
            return iconType.stringValue()
        }
        set(string) {
            iconType = IconHalfCloudType(stringVal: string)
        }
    }
    
    override var isFlipped: Bool {
        return true
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    var isDownloadAnimationInProgress: Bool {
        return layerArrowDown?.animation(forKey: "downloadAnimation") != nil
    }
    
    var isUploadAnimationInProgress: Bool {
        return layerArrowUp?.animation(forKey: "uploadAnimation") != nil
    }
    
    func playUploadAnimation() {
        if isUploadAnimationInProgress {
            return
        }
        
        if let animation = animationPosition(byValue: -4) {
            layerArrowUp?.add(animation, forKey: "uploadAnimation")
        }
        
        animateScale()
    }
    
    func stopUploadAnimation() {
        let pOrigin = layerArrowUp?.position
        let pLayer = layerArrowUp?.presentation()
        layerArrowUp?.position = pLayer?.position ?? CGPoint.zero
        layerArrowUp?.opacity = pLayer?.opacity ?? 0.0
        layerArrowUp?.removeAllAnimations()
        
        layerArrowUp?.opacity = 1.0
        layerArrowUp?.position = pOrigin ?? CGPoint.zero
    }
    
    func playDownloadAnimation() {
        if isDownloadAnimationInProgress {
            return
        }
        
        if let animation = animationPosition(byValue: 4) {
            layerArrowDown?.add(animation, forKey: "downloadAnimation")
        }
        
        animateScale()
    }
    
    func stopDownloadAnimation() {
        let pOrigin = layerArrowDown?.position
        let pLayer = layerArrowDown?.presentation()
        layerArrowDown?.position = pLayer?.position ?? CGPoint.zero
        layerArrowDown?.opacity = pLayer?.opacity ?? 0.0
        layerArrowDown?.removeAllAnimations()
        
        layerArrowDown?.opacity = 1.0
        layerArrowDown?.position = pOrigin ?? CGPoint.zero
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupValues()
    }
    
    
    func setupValues() {
        self.wantsLayer = true
        createLayers()
        setLayersColors()
    }
    
    func createLayers() {
        _frame = self.frame
        _frame.origin = CGPoint(x: _frame.width * 0.15, y: _frame.height * 0.2)
        layerCloud = CAShapeLayer()
        layerArrowUp = CAShapeLayer()
        layerArrowDown = CAShapeLayer()
        
        //layerCloud?.frame = CGRect(x: 0, y: 0, width: self.frame.size.width * 0.6, height: self.frame.size.height * 0.6)
        layerCloud?.lineWidth = 1.0
        layerArrowUp?.lineWidth = (layerCloud?.lineWidth ?? 1.0) + 0.2
        layerArrowDown?.lineWidth = layerArrowUp!.lineWidth
        
        layerArrowDown?.lineCap = .round
        layerArrowUp?.lineCap = layerArrowDown!.lineCap
        layerCloud?.lineCap = layerArrowUp!.lineCap
        
        layerCloud?.path = cloudPath()
        layerArrowDown?.path = arrowDownPath()
        layerArrowUp?.path = arrowUpPath()
        
        if let layerArrowUp = layerArrowUp {
            layerCloud?.addSublayer(layerArrowUp)
        }
        if let layerArrowDown = layerArrowDown {
            layerCloud?.addSublayer(layerArrowDown)
        }
        
        if let layerCloud = layerCloud {
            layer?.addSublayer(layerCloud)
        }
    }
    
    private var _tintColor: NSColor = .labelColor
    @IBInspectable @objc dynamic var tintColor: NSColor! {
        get {
            return _tintColor
        }
        set(color) {
            _tintColor = color
            setLayersColors()
        }
    }
    
    func setLayersColors() {
        layerCloud?.fillColor = NSColor.clear.cgColor
        layerArrowDown?.fillColor = NSColor.clear.cgColor
        layerArrowUp?.fillColor = NSColor.clear.cgColor
        
        layerCloud?.strokeColor = tintColor.cgColor
        layerArrowDown?.strokeColor = tintColor.cgColor
        layerArrowUp?.strokeColor = tintColor.cgColor
        updateLayer()
    }
    
    func animateScale() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setCompletionBlock({
            self.layerCloud!.transform = CATransform3DIdentity
        })
        layerCloud?.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
        CATransaction.commit()
    }
    
    func animationPosition(byValue val: CGFloat) -> CAAnimation? {
        let grp = CAAnimationGroup()
        grp.duration = 2.0
        grp.repeatCount = .greatestFiniteMagnitude
        
        let a0 = CABasicAnimation(keyPath: "position.y")
        a0.beginTime = 0
        a0.duration = 1.5
        a0.byValue = NSNumber(value: Float(val))
        
        let a1 = CABasicAnimation(keyPath: "opacity")
        a1.beginTime = 0.5
        a1.duration = 1.0
        a1.fromValue = NSNumber(value: 1.0)
        a1.toValue = NSNumber(value: 0.0)
        
        let a2 = CABasicAnimation(keyPath: "opacity")
        a2.beginTime = 1.5
        a2.duration = 0.5
        a2.fromValue = NSNumber(value: 0)
        a2.toValue = NSNumber(value: 1)
        
        grp.animations = [a0, a1, a2]
        return grp
    }
    
    func cloudPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        layerCloud!.frame = self._frame
    
        if path == nil {
            let w = self.frame.size.width * 0.65
            let h = self.frame.size.height * 0.65
            
            let cloudPath = NSBezierPath()
            cloudPath.move(to: CGPoint(x: 0.87551 * w, y: 0.06000 * h))
            cloudPath.curve(to: CGPoint(x: 0.67878 * w, y: 0.00694 * h), controlPoint1: CGPoint(x: 0.81673 * w, y: 0.02531 * h), controlPoint2: CGPoint(x: 0.75143 * w, y: 0.00694 * h))
            cloudPath.curve(to: CGPoint(x: 0.40939 * w, y: 0.11918 * h), controlPoint1: CGPoint(x: 0.57429 * w, y: 0.00694 * h), controlPoint2: CGPoint(x: 0.48449 * w, y: 0.04449 * h))
            cloudPath.curve(to: CGPoint(x: 0.29714 * w, y: 0.39184 * h), controlPoint1: CGPoint(x: 0.33429 * w, y: 0.19388 * h), controlPoint2: CGPoint(x: 0.29714 * w, y: 0.28490 * h))
            cloudPath.curve(to: CGPoint(x: 0.30367 * w, y: 0.40980 * h), controlPoint1: CGPoint(x: 0.29714 * w, y: 0.40082 * h), controlPoint2: CGPoint(x: 0.30000 * w, y: 0.40612 * h))
            cloudPath.line(to: CGPoint(x: 0.29714 * w, y: 0.40980 * h))
            cloudPath.curve(to: CGPoint(x: 0.09020 * w, y: 0.49551 * h), controlPoint1: CGPoint(x: 0.21633 * w, y: 0.40980 * h), controlPoint2: CGPoint(x: 0.14735 * w, y: 0.43837 * h))
            cloudPath.curve(to: CGPoint(x: 0.00449 * w, y: 0.70245 * h), controlPoint1: CGPoint(x: 0.03306 * w, y: 0.55265 * h), controlPoint2: CGPoint(x: 0.00449 * w, y: 0.62163 * h))
            cloudPath.curve(to: CGPoint(x: 0.09020 * w, y: 0.90939 * h), controlPoint1: CGPoint(x: 0.00449 * w, y: 0.78327 * h), controlPoint2: CGPoint(x: 0.03306 * w, y: 0.85224 * h))
            cloudPath.curve(to: CGPoint(x: 0.29714 * w, y: 0.99510 * h), controlPoint1: CGPoint(x: 0.14735 * w, y: 0.96653 * h), controlPoint2: CGPoint(x: 0.21633 * w, y: 0.99510 * h))
            cloudPath.line(to: CGPoint(x: 0.87551 * w, y: 0.99510 * h))
            
            path = cloudPath.cgPath
        }
        return path
    }
    
    func frame2() -> CGRect {
        let w = self.frame.size.width * 0.65
        let h = self.frame.size.height * 0.65
        
        return CGRect(x: floor(w * 0.9 + 0.5), y: floor(h * 0.18776 + 0.5), width: floor(w * 1.11837 + 0.5) - floor(w * 0.76327 + 0.5), height: floor(h * 0.92245 + 0.5) - floor(h * 0.18776 + 0.5))
        
    }
    
    func arrowUpPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        let frame2 = self.frame2()
        layerArrowUp?.frame = frame2
        
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            
            let arrowUpPath = NSBezierPath()
            arrowUpPath.move(to: CGPoint(x: 0.49877 * w, y: 0.00611 * h))
            arrowUpPath.line(to: CGPoint(x: 0.49893 * w, y: 0.98167 * h))
            arrowUpPath.move(to: CGPoint(x: 0.01720 * w, y: 0.23002 * h))
            arrowUpPath.line(to: CGPoint(x: 0.49877 * w, y: 0.00611 * h))
            arrowUpPath.move(to: CGPoint(x: 0.98042 * w, y: 0.22998 * h))
            arrowUpPath.line(to: CGPoint(x: 0.49877 * w, y: 0.00611 * h))
            path = arrowUpPath.cgPath
        }
        return path
    }
    
    func arrowDownPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        let frame2 = self.frame2()
        layerArrowDown?.frame = frame2
        
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            
            let arrowDownPath = NSBezierPath()
            arrowDownPath.move(to: CGPoint(x: 0.49884 * w, y: 0.98167 * h))
            arrowDownPath.line(to: CGPoint(x: 0.49868 * w, y: 0.00611 * h))
            arrowDownPath.move(to: CGPoint(x: 0.98042 * w, y: 0.75776 * h))
            arrowDownPath.line(to: CGPoint(x: 0.49884 * w, y: 0.98167 * h))
            arrowDownPath.move(to: CGPoint(x: 0.01720 * w, y: 0.75780 * h))
            arrowDownPath.line(to: CGPoint(x: 0.49884 * w, y: 0.98167 * h))
            
            path = arrowDownPath.cgPath
        }
        return path
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupValues()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupValues()
        let string = self.typeString
        self.iconType = IconHalfCloudType(stringVal: string)
        updateLayer()
    }
}


#endif

#if !os(macOS) || targetEnvironment(macCatalyst)
import UIKit

@IBDesignable @objcMembers
class IconHalfCloud: UIView {
    private var layerCloud: CAShapeLayer?
    private var layerArrowUp: CAShapeLayer?
    private var layerArrowDown: CAShapeLayer?
    
    private var _iconType: IconHalfCloudType!
    var iconType: IconHalfCloudType! {
        get {
            return _iconType
        }
        set(iconType) {
            _iconType = iconType
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            
            layerArrowDown?.isHidden = true
            layerArrowUp?.isHidden = true
            
            switch iconType {
                case .download:
                    layerArrowDown?.isHidden = false
                case .upload:
                    layerArrowUp?.isHidden = false
                default:
                    break
            }
            
            CATransaction.commit()
        }
    }
    
    @IBInspectable @objc dynamic var typeString: String {
        get {
            return iconType.stringValue()
        }
        set(string) {
            iconType = IconHalfCloudType(stringVal: string)
        }
    }
    
    var isDownloadAnimationInProgress: Bool {
        return layerArrowDown?.animation(forKey: "downloadAnimation") != nil
    }
    
    var isUploadAnimationInProgress: Bool {
        return layerArrowUp?.animation(forKey: "uploadAnimation") != nil
    }
    
    func playUploadAnimation() {
        if isUploadAnimationInProgress {
            return
        }
        
        if let animation = animationPosition(byValue: -4) {
            layerArrowUp?.add(animation, forKey: "uploadAnimation")
        }
        
        animateScale()
    }
    
    func stopUploadAnimation() {
        let pOrigin = layerArrowUp?.position
        let pLayer = layerArrowUp?.presentation()
        layerArrowUp?.position = pLayer?.position ?? CGPoint.zero
        layerArrowUp?.opacity = pLayer?.opacity ?? 0.0
        layerArrowUp?.removeAllAnimations()
        
        layerArrowUp?.opacity = 1.0
        layerArrowUp?.position = pOrigin ?? CGPoint.zero
    }
    
    func playDownloadAnimation() {
        if isDownloadAnimationInProgress {
            return
        }
        
        if let animation = animationPosition(byValue: 4) {
            layerArrowDown?.add(animation, forKey: "downloadAnimation")
        }
        
        animateScale()
    }
    
    func stopDownloadAnimation() {
        let pOrigin = layerArrowDown?.position
        let pLayer = layerArrowDown?.presentation()
        layerArrowDown?.position = pLayer?.position ?? CGPoint.zero
        layerArrowDown?.opacity = pLayer?.opacity ?? 0.0
        layerArrowDown?.removeAllAnimations()
        
        layerArrowDown?.opacity = 1.0
        layerArrowDown?.position = pOrigin ?? CGPoint.zero
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupValues()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupValues()
    }
    
    func setupValues() {
        createLayers()
        setLayersColors()
    }
    
    func createLayers() {
        layerCloud = CAShapeLayer()
        layerArrowUp = CAShapeLayer()
        layerArrowDown = CAShapeLayer()
        
        layerCloud?.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        layerCloud?.lineWidth = 1.5
        
        layerArrowUp?.lineWidth = (layerCloud?.lineWidth ?? 0.0) + 0.5
        layerArrowDown?.lineWidth = layerArrowUp!.lineWidth
        
        layerArrowDown?.lineCap = .round
        layerArrowUp?.lineCap = layerArrowDown!.lineCap
        layerCloud?.lineCap = layerArrowUp!.lineCap
        
        layerCloud?.path = cloudPath()
        layerArrowDown?.path = arrowDownPath()
        layerArrowUp?.path = arrowUpPath()
        
        if let layerArrowUp = layerArrowUp {
            layerCloud?.addSublayer(layerArrowUp)
        }
        if let layerArrowDown = layerArrowDown {
            layerCloud?.addSublayer(layerArrowDown)
        }
        
        if let layerCloud = layerCloud {
            layer.addSublayer(layerCloud)
        }
    }
    
    
    override var tintColor: UIColor! {
        didSet {
            setLayersColors()
        }
    }
    
    func setLayersColors() {
        layerCloud?.fillColor = UIColor.clear.cgColor
        layerArrowDown?.fillColor = UIColor.clear.cgColor
        layerArrowUp?.fillColor = UIColor.clear.cgColor
        
        layerCloud?.strokeColor = tintColor.cgColor
        layerArrowDown?.strokeColor = tintColor.cgColor
        layerArrowUp?.strokeColor = tintColor.cgColor
    }
    
    func animateScale() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setCompletionBlock({
            self.layerCloud!.transform = CATransform3DIdentity
        })
        layerCloud?.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
        CATransaction.commit()
    }
    
    func animationPosition(byValue val: CGFloat) -> CAAnimation? {
        let grp = CAAnimationGroup()
        grp.duration = 2.0
        grp.repeatCount = .greatestFiniteMagnitude
        
        let a0 = CABasicAnimation(keyPath: "position.y")
        a0.beginTime = 0
        a0.duration = 1.5
        a0.byValue = NSNumber(value: Float(val))
        
        let a1 = CABasicAnimation(keyPath: "opacity")
        a1.beginTime = 0.5
        a1.duration = 1.0
        a1.fromValue = NSNumber(value: 1.0)
        a1.toValue = NSNumber(value: 0.0)
        
        let a2 = CABasicAnimation(keyPath: "opacity")
        a2.beginTime = 1.5
        a2.duration = 0.5
        a2.fromValue = NSNumber(value: 0)
        a2.toValue = NSNumber(value: 1)
        
        grp.animations = [a0, a1, a2]
        return grp
    }
    
    func cloudPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        if path == nil {
            let w = frame.size.width
            let h = frame.size.height
            
            let cloudPath = UIBezierPath()
            cloudPath.move(to: CGPoint(x: 0.87551 * w, y: 0.06000 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.67878 * w, y: 0.00694 * h), controlPoint1: CGPoint(x: 0.81673 * w, y: 0.02531 * h), controlPoint2: CGPoint(x: 0.75143 * w, y: 0.00694 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.40939 * w, y: 0.11918 * h), controlPoint1: CGPoint(x: 0.57429 * w, y: 0.00694 * h), controlPoint2: CGPoint(x: 0.48449 * w, y: 0.04449 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.29714 * w, y: 0.39184 * h), controlPoint1: CGPoint(x: 0.33429 * w, y: 0.19388 * h), controlPoint2: CGPoint(x: 0.29714 * w, y: 0.28490 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.30367 * w, y: 0.40980 * h), controlPoint1: CGPoint(x: 0.29714 * w, y: 0.40082 * h), controlPoint2: CGPoint(x: 0.30000 * w, y: 0.40612 * h))
            cloudPath.addLine(to: CGPoint(x: 0.29714 * w, y: 0.40980 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.09020 * w, y: 0.49551 * h), controlPoint1: CGPoint(x: 0.21633 * w, y: 0.40980 * h), controlPoint2: CGPoint(x: 0.14735 * w, y: 0.43837 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.00449 * w, y: 0.70245 * h), controlPoint1: CGPoint(x: 0.03306 * w, y: 0.55265 * h), controlPoint2: CGPoint(x: 0.00449 * w, y: 0.62163 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.09020 * w, y: 0.90939 * h), controlPoint1: CGPoint(x: 0.00449 * w, y: 0.78327 * h), controlPoint2: CGPoint(x: 0.03306 * w, y: 0.85224 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.29714 * w, y: 0.99510 * h), controlPoint1: CGPoint(x: 0.14735 * w, y: 0.96653 * h), controlPoint2: CGPoint(x: 0.21633 * w, y: 0.99510 * h))
            cloudPath.addLine(to: CGPoint(x: 0.87551 * w, y: 0.99510 * h))
            
            path = cloudPath.cgPath
        }
        return path
    }
    
    func frame2() -> CGRect {
        let w = frame.size.width
        let h = frame.size.height
        
        return CGRect(x: floor(w * 0.9 + 0.5), y: floor(h * 0.18776 + 0.5), width: floor(w * 1.11837 + 0.5) - floor(w * 0.76327 + 0.5), height: floor(h * 0.92245 + 0.5) - floor(h * 0.18776 + 0.5))
        
    }
    
    func arrowUpPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        let frame2 = self.frame2()
        layerArrowUp?.frame = frame2
        
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            
            let arrowUpPath = UIBezierPath()
            arrowUpPath.move(to: CGPoint(x: 0.49877 * w, y: 0.00611 * h))
            arrowUpPath.addLine(to: CGPoint(x: 0.49893 * w, y: 0.98167 * h))
            arrowUpPath.move(to: CGPoint(x: 0.01720 * w, y: 0.23002 * h))
            arrowUpPath.addLine(to: CGPoint(x: 0.49877 * w, y: 0.00611 * h))
            arrowUpPath.move(to: CGPoint(x: 0.98042 * w, y: 0.22998 * h))
            arrowUpPath.addLine(to: CGPoint(x: 0.49877 * w, y: 0.00611 * h))
            path = arrowUpPath.cgPath
        }
        return path
    }
    
    func arrowDownPath() -> CGPath? {
        //static
        var path: CGPath? = nil
        
        let frame2 = self.frame2()
        layerArrowDown?.frame = frame2
        
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            
            let arrowDownPath = UIBezierPath()
            arrowDownPath.move(to: CGPoint(x: 0.49884 * w, y: 0.98167 * h))
            arrowDownPath.addLine(to: CGPoint(x: 0.49868 * w, y: 0.00611 * h))
            arrowDownPath.move(to: CGPoint(x: 0.98042 * w, y: 0.75776 * h))
            arrowDownPath.addLine(to: CGPoint(x: 0.49884 * w, y: 0.98167 * h))
            arrowDownPath.move(to: CGPoint(x: 0.01720 * w, y: 0.75780 * h))
            arrowDownPath.addLine(to: CGPoint(x: 0.49884 * w, y: 0.98167 * h))
            
            path = arrowDownPath.cgPath
        }
        return path
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupValues()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupValues()
        let string = self.typeString
        self.iconType = IconHalfCloudType(stringVal: string)
        setNeedsDisplay()
    }
}

#endif

