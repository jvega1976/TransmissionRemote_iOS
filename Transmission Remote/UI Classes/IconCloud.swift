//
//  IconCloud.swift
//  IconTestApp
//
//  Created by Alexey Chechetkin on 18.08.15.
//  Copyright (c) 2015 Alexey Chechetkin. All rights reserved.
//
import UIKit

enum IconCloudType : Int {
    case Upload
    case Wait
    case Download
    case Verify
    case Pause
    case Error
    case Active
    case All
    case None
    case Completed
    
    func stringValue() -> String {
        switch self {
            case .Upload: return "Uploading"
            case .Wait: return "Waiting"
            case .Download: return "Downloading"
            case .Verify: return "Verifying"
            case .Pause: return "Paused"
            case .Error: return "Error"
            case .Active: return "Active"
            case .All: return "All"
            case .None: return "None"
            case .Completed: return "Completed"
        }
    }
}

@objcMembers
class IconCloud: UIView {
    
    var iconType = IconCloudType.None {
        didSet {
            /// REMOVE ALL ANIMATIONS
            layerArrowUp?.removeAllAnimations()
            layerArrowDown?.removeAllAnimations()
            layerCircleArrows?.removeAllAnimations()
            layerLittleArrowDown?.removeAllAnimations()
            layerLittleArrowUp?.removeAllAnimations()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            /// HIDE LAYERS
            layerCloud?.isHidden = false
            layerArrows?.isHidden = true
            layerClouds?.isHidden = layerArrows!.isHidden
            layerLittleArrowDown?.isHidden = layerClouds!.isHidden
            layerLittleArrowUp?.isHidden = layerLittleArrowDown!.isHidden
            layerCrossButton?.isHidden = layerLittleArrowUp!.isHidden
            layerWaitArrow?.isHidden = layerCrossButton!.isHidden
            layerWaitButton?.isHidden = layerWaitArrow!.isHidden
            layerValidButton?.isHidden = layerWaitButton!.isHidden
            layerStopButton?.isHidden = layerValidButton!.isHidden
            layerArrowUp?.isHidden = layerStopButton!.isHidden
            layerArrowDown?.isHidden = layerArrowUp!.isHidden
            layerCircleArrows?.isHidden = layerArrowDown!.isHidden
            
            switch iconType {
                case IconCloudType.Download:
                    layerArrowDown?.isHidden = false
                    break
                case IconCloudType.Upload:
                    layerArrowUp?.isHidden = false
                    break
                case IconCloudType.Wait:
                    layerWaitButton!.isHidden = false
                    layerWaitArrow!.isHidden = false
                    break
                case IconCloudType.Verify:
                    layerCircleArrows?.isHidden = false
                    break
                case IconCloudType.Pause:
                    layerStopButton?.isHidden = false
                    break
                case IconCloudType.Error:
                    layerCrossButton?.isHidden = false
                    break
                case IconCloudType.Active:
                    layerLittleArrowDown?.isHidden = false
                    layerLittleArrowUp?.isHidden = false
                    break
                case IconCloudType.Completed:
                    layerValidButton?.isHidden = false
                    break
                case IconCloudType.All:
                    layerArrows?.isHidden = false
                    layerClouds?.isHidden = false
                    layerCloud?.isHidden = true
                    break
                default:
                    break
            }
            CATransaction.commit()
        }
    }
    
    /// bunch of layers
    private var layerCloud: CAShapeLayer!
    private var layerArrowUp: CAShapeLayer!
    private var layerArrowDown: CAShapeLayer!
    private var layerCircleArrows: CAShapeLayer!
    private var layerStopButton: CAShapeLayer!
    private var layerValidButton: CAShapeLayer!
    private var layerWaitButton: CAShapeLayer!
    private var layerWaitArrow: CAShapeLayer!
    private var layerCrossButton: CAShapeLayer!
    private var layerLittleArrowUp: CAShapeLayer!
    private var layerLittleArrowDown: CAShapeLayer!
    private var layerClouds: CAShapeLayer!
    private var layerArrows: CAShapeLayer!
    /// main layer frame
    private var _frame:CGRect!
    
   override init(frame: CGRect) {
        super.init(frame: frame)
        self.tintAdjustmentMode = .normal
        setupValues()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.tintAdjustmentMode = .normal
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupValues()
    }
    
    func setupValues() {
        createLayers()
        setLayersColors()
        iconType = IconCloudType.None
    }
    
    func animateScale() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setCompletionBlock({
            self.layerCloud?.transform = CATransform3DIdentity
        })
        layerCloud?.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
        CATransaction.commit()
    }
    
    func playCheckAnimation() {
        if isCheckAnimationInProgress {
            return
        }
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.duration = 2.0
        anim.fromValue = 0.0
        anim.toValue = -2 * Double.pi
        anim.repeatCount = HUGE
        layerCircleArrows?.add(anim, forKey: "checkAnimation")
        animateScale()
    }
    
    func playWaitAnimation() {
        if isWaitAnimationInProgres {
            return
        }
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.duration = 2.0
        anim.fromValue = 0.0
        anim.toValue = -2 * Double.pi
        anim.repeatCount = HUGE
        layerWaitButton?.add(anim, forKey: "waitAnimation")
        animateScale()
    }
    
    func stopCheckAnimation() {
        let anim = layerCircleArrows?.animation(forKey: "checkAnimation")
        if anim != nil {
            let mtx = (layerCircleArrows?.presentation())?.transform
            if let mtx = mtx {
                layerCircleArrows?.transform = mtx
            }
            layerCircleArrows?.removeAllAnimations()
            layerCircleArrows?.transform = CATransform3DIdentity
        }
    }
    
    func stopWaitAnimation() {
        let anim = layerWaitButton?.animation(forKey: "waitAnimation")
        if anim != nil {
            let mtx = (layerWaitButton?.presentation())?.transform
            if let mtx = mtx {
                layerWaitButton?.transform = mtx
            }
            layerWaitButton?.removeAllAnimations()
            layerWaitButton?.transform = CATransform3DIdentity
        }
    }
    
    var isCheckAnimationInProgress: Bool {
        return layerCircleArrows?.animation(forKey: "checkAnimation") != nil
    }
    
    var isWaitAnimationInProgres: Bool {
        return layerWaitButton?.animation(forKey: "waitAnimation") != nil
    }
    
    func playUploadAnimation() {
        if isUploadAnimationInProgress {
            return
        }
        let grp = CAAnimationGroup()
        grp.duration = 2.0
        grp.repeatCount = HUGE
        let a0 = CABasicAnimation(keyPath: "position.y")
        a0.beginTime = 0
        a0.duration = 1.5
        a0.byValue = -7
        let a1 = CABasicAnimation(keyPath: "opacity")
        a1.beginTime = 0.5
        a1.duration = 1.0
        a1.fromValue =  1.0
        a1.toValue =  0.0
        let a2 = CABasicAnimation(keyPath: "opacity")
        a2.beginTime = 1.5
        a2.duration = 0.5
        a2.fromValue = 0
        a2.toValue = 1
        grp.animations = [a0, a1, a2]
        layerArrowUp?.add(grp, forKey: "uploadAnimation")
        animateScale()
    }
    
    var isUploadAnimationInProgress: Bool {
        return layerArrowUp?.animation(forKey: "uploadAnimation") != nil
    }
    
    func stopUploadAnimation() {
        let pOrigin = layerArrowUp?.position
        let pLayer = layerArrowUp?.presentation()
        layerArrowUp?.position = pLayer?.position ?? CGPoint.zero
        layerArrowUp?.opacity = pLayer?.opacity ?? 0.0
        layerArrowUp?.removeAllAnimations()
        layerArrowUp?.position = pOrigin ?? CGPoint.zero
        layerArrowUp?.opacity = 1.0
    }
    
    func playDownloadAnimation() {
        if isDownloadAnimationInProgress {
            return
        }
        let grp = CAAnimationGroup()
        grp.duration = 2.0
        grp.repeatCount = HUGE
        let a0 = CABasicAnimation(keyPath: "position.y")
        a0.beginTime = 0
        a0.duration = 1.5
        a0.byValue = 7
        let a1 = CABasicAnimation(keyPath: "opacity")
        a1.beginTime = 0.5
        a1.duration = 1.0
        a1.fromValue = 1.0
        a1.toValue = 0.0
        let a2 = CABasicAnimation(keyPath: "opacity")
        a2.beginTime = 1.5
        a2.duration = 0.5
        a2.fromValue = 0
        a2.toValue = 1
        grp.animations = [a0, a1, a2]
        layerArrowDown?.add(grp, forKey: "downloadAnimation")
        animateScale()
    }
    
    func stopDownloadAnimation() {
        let pOrigin = layerArrowDown?.position
        let pLayer = layerArrowDown?.presentation()
        layerArrowDown?.position = pLayer?.position ?? CGPoint.zero
        layerArrowDown?.opacity = pLayer?.opacity ?? 0.0
        layerArrowDown?.removeAllAnimations()
        layerArrowDown?.position = pOrigin ?? CGPoint.zero
        layerArrowDown?.opacity = 1.0
    }
    
    var isDownloadAnimationInProgress: Bool {
        return layerArrowDown?.animation(forKey: "downloadAnimation") != nil
    }
    
    func playActivityAnimation() {
        if isActivityAnimationInProgress {
            return
        }
        let a0 = CABasicAnimation(keyPath: "position.y")
        a0.beginTime = 0
        a0.duration = 1.5
        a0.autoreverses = true
        a0.repeatCount = HUGE
        a0.byValue = -3
        layerLittleArrowUp?.add(a0, forKey: "activityAnimationUp")
        let a1 = CABasicAnimation(keyPath: "position.y")
        a1.beginTime = 0
        a1.duration = 1.5
        a1.autoreverses = true
        a1.repeatCount = HUGE
        a1.byValue = 3
        layerLittleArrowDown?.add(a1, forKey: "activityAnimationDown")
        animateScale()
    }
    
    func stopActivityAnimation() {
        var pOrigin = layerLittleArrowDown?.position
        var pLayer = layerLittleArrowDown?.presentation()
        layerLittleArrowDown?.position = pLayer?.position ?? CGPoint.zero
        layerLittleArrowDown?.removeAllAnimations()
        layerLittleArrowDown?.position = pOrigin ?? CGPoint.zero
        pOrigin = layerLittleArrowUp?.position
        pLayer = layerLittleArrowUp?.presentation()
        layerLittleArrowUp?.position = pLayer?.position ?? CGPoint.zero
        layerLittleArrowUp?.removeAllAnimations()
        layerLittleArrowUp?.position = pOrigin ?? CGPoint.zero
    }
    
    var isActivityAnimationInProgress:Bool {
        return layerLittleArrowUp?.animation(forKey: "activityAnimationUp") != nil
    }
    
    func createLayers() {
//        UIGraphicsBeginImageContext(self.frame.size)
        //frame = frame    // Skipping redundant initializing to itself
        _frame = self.frame
        _frame!.origin = CGPoint.zero
        /////////////////////////////////////
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        /////////////////////////////////////
        /// CREATE
        layerCloud = CAShapeLayer()
        layerArrowUp = CAShapeLayer()
        layerArrowDown = CAShapeLayer()
        layerCircleArrows = CAShapeLayer()
        layerStopButton = CAShapeLayer()
        layerCrossButton = CAShapeLayer()
        layerValidButton = CAShapeLayer()
        layerWaitButton = CAShapeLayer()
        layerWaitArrow = CAShapeLayer()
        layerLittleArrowDown = CAShapeLayer()
        layerLittleArrowUp = CAShapeLayer()
        layerClouds = CAShapeLayer()
        layerArrows = CAShapeLayer()
        /// SCALE
        layerArrows?.contentsScale = UIScreen.main.scale
        layerClouds?.contentsScale = layerArrows!.contentsScale
        layerLittleArrowUp?.contentsScale = layerClouds!.contentsScale
        layerLittleArrowDown?.contentsScale = layerLittleArrowUp!.contentsScale
        layerWaitArrow?.contentsScale = layerLittleArrowDown!.contentsScale
        layerWaitButton?.contentsScale = layerWaitArrow!.contentsScale
        layerValidButton?.contentsScale = layerWaitButton!.contentsScale
        layerStopButton?.contentsScale = layerValidButton!.contentsScale
        layerCircleArrows?.contentsScale = layerStopButton!.contentsScale
        layerArrowDown?.contentsScale = layerCircleArrows!.contentsScale
        layerArrowUp?.contentsScale = layerArrowDown!.contentsScale
        layerCloud?.contentsScale = layerArrowUp!.contentsScale
        layerCrossButton?.contentsScale = layerCloud!.contentsScale
        /// LINE WIDTH
        layerArrows?.lineWidth = 1.5
        layerLittleArrowDown?.lineWidth = layerArrows!.lineWidth
        layerLittleArrowUp?.lineWidth = layerLittleArrowDown!.lineWidth
        layerWaitArrow?.lineWidth = layerLittleArrowUp!.lineWidth
        layerWaitButton?.lineWidth = layerWaitArrow!.lineWidth
        layerValidButton?.lineWidth = layerWaitButton!.lineWidth
        layerStopButton?.lineWidth = layerValidButton!.lineWidth
        layerCircleArrows?.lineWidth = layerStopButton!.lineWidth
        layerArrowDown?.lineWidth = layerCircleArrows!.lineWidth
        layerArrowUp?.lineWidth = layerArrowDown!.lineWidth
        layerCrossButton?.lineWidth = layerArrowUp!.lineWidth
        layerClouds?.lineWidth = 2.0
        layerCloud?.lineWidth = layerClouds!.lineWidth
        /// LINE CAPS
        layerClouds?.lineCap = .round
        layerArrows?.lineCap = layerClouds!.lineCap
        layerLittleArrowDown?.lineCap = layerArrows!.lineCap
        layerLittleArrowUp?.lineCap = layerLittleArrowDown!.lineCap
        layerWaitArrow?.lineCap = layerLittleArrowUp!.lineCap
        layerWaitButton?.lineCap = layerWaitArrow!.lineCap
        layerValidButton?.lineCap = layerWaitButton!.lineCap
        layerStopButton?.lineCap = layerValidButton!.lineCap
        layerArrowUp?.lineCap = layerStopButton!.lineCap
        layerArrowDown?.lineCap = layerArrowUp!.lineCap
        layerCloud?.lineCap = layerArrowDown!.lineCap
        layerCrossButton?.lineCap = layerCloud!.lineCap
        layerCircleArrows?.lineCap = .square
        /// SET PATHS
        layerCloud?.path = cloudPath
        layerCircleArrows?.path = circleArrowsPath
        layerArrowDown?.path = arrowDownPath
        layerArrowUp?.path = arrowUpPath
        layerStopButton?.path = stopButtonPath
        layerValidButton?.path = validButtonPath
        layerWaitButton?.path = waitButtonPath
        layerWaitArrow?.path = waitArrowPath
        layerCrossButton?.path = crossButtonPath
        layerLittleArrowDown?.path = littleArrowDownPath
        layerLittleArrowUp?.path = littleArrowUpPath
        layerArrows?.path = arrowsPath
        layerClouds?.path = cloudsPath
        /// ADD TO VIEW
        if let layerCloud = layerCloud {
            layer.addSublayer(layerCloud)
        }
        if let layerClouds = layerClouds {
            layer.addSublayer(layerClouds)
        }
        if let layerArrows = layerArrows {
            layer.addSublayer(layerArrows)
        }
        if let layerCircleArrows = layerCircleArrows {
            layerCloud?.addSublayer(layerCircleArrows)
        }
        if let layerArrowDown = layerArrowDown {
            layerCloud?.addSublayer(layerArrowDown)
        }
        if let layerArrowUp = layerArrowUp {
            layerCloud?.addSublayer(layerArrowUp)
        }
        if let layerStopButton = layerStopButton {
            layerCloud?.addSublayer(layerStopButton)
        }
        if let layerValidButton = layerValidButton {
            layerCloud?.addSublayer(layerValidButton)
        }
        if let layerWaitButton = layerWaitButton {
            layerCloud?.addSublayer(layerWaitButton)
        }
        if let layerWaitArrow = layerWaitArrow {
            layerCloud?.addSublayer(layerWaitArrow)
        }
        if let layerCrossButton = layerCrossButton {
            layerCloud?.addSublayer(layerCrossButton)
        }
        if let layerLittleArrowDown = layerLittleArrowDown {
            layerCloud?.addSublayer(layerLittleArrowDown)
        }
        if let layerLittleArrowUp = layerLittleArrowUp {
            layerCloud?.addSublayer(layerLittleArrowUp)
        }
        //////////////////////
        CATransaction.commit()
    }
    
    func tintColor(_ tintColor: UIColor!) {
        self.tintColor = tintColor
    }
    
    
    override var tintColor: UIColor! {
        didSet {
            setLayersColors()
        }
    }
    
    func setLayersColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        /// STROKE
        layerArrows?.strokeColor = tintColor.cgColor
        layerClouds?.strokeColor = layerArrows?.strokeColor
        layerLittleArrowDown?.strokeColor = layerClouds?.strokeColor
        layerLittleArrowUp?.strokeColor = layerLittleArrowDown?.strokeColor
        layerCrossButton?.strokeColor = layerLittleArrowUp?.strokeColor
        layerWaitArrow?.strokeColor = layerCrossButton?.strokeColor
        layerWaitButton?.strokeColor = layerWaitArrow?.strokeColor
        layerValidButton?.strokeColor = layerWaitButton?.strokeColor
        layerStopButton?.strokeColor = layerValidButton?.strokeColor
        layerCircleArrows?.strokeColor = layerStopButton?.strokeColor
        layerArrowDown?.strokeColor = layerCircleArrows?.strokeColor
        layerArrowUp?.strokeColor = layerArrowDown?.strokeColor
        layerCloud?.strokeColor = layerArrowUp?.strokeColor
        /// FILL
        layerClouds?.fillColor = nil
        layerArrows?.fillColor = layerClouds?.fillColor
        layerLittleArrowDown?.fillColor = layerArrows?.fillColor
        layerLittleArrowUp?.fillColor = layerLittleArrowDown?.fillColor
        layerWaitArrow?.fillColor = layerLittleArrowUp?.fillColor
        layerWaitButton?.fillColor = layerWaitArrow?.fillColor
        layerValidButton?.fillColor = layerWaitButton?.fillColor
        layerStopButton?.fillColor = layerValidButton?.fillColor
        layerCircleArrows?.fillColor = layerStopButton?.fillColor
        layerArrowDown?.fillColor = layerCircleArrows?.fillColor
        layerArrowUp?.fillColor = layerArrowDown?.fillColor
        layerCloud?.fillColor = layerArrowUp?.fillColor
        layerCrossButton?.fillColor = layerCloud?.fillColor
        CATransaction.commit()
    }
    
    func iconType(_ iconType: IconCloudType) {
        if self.iconType == iconType {
            return
        }
        self.iconType = iconType
    }
    
    var image: UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.frame.size)
        let img = renderer.image { context in
            switch iconType {
            case IconCloudType.Download:
                layerCloud.render(in: context.cgContext)
//                layerArrowDown.render(in: context.cgContext)
                break
            case IconCloudType.Upload:
                layerCloud.render(in: context.cgContext)
//                layerArrowUp.render(in: context.cgContext)
                break
            case IconCloudType.Wait:
                layerCloud.render(in: context.cgContext)
//                layerWaitButton.render(in: context.cgContext)
//                layerWaitArrow.render(in: context.cgContext)
                break
            case IconCloudType.Verify:
                 layerCloud.render(in: context.cgContext)
 //               layerCircleArrows.render(in: context.cgContext)
                break
            case IconCloudType.Pause:
                layerCloud.render(in: context.cgContext)
//                layerStopButton.render(in: context.cgContext)
                break
            case IconCloudType.Error:
                 layerCloud.render(in: context.cgContext)
 //               layerCrossButton.render(in: context.cgContext)
                break
            case IconCloudType.Active:
                layerCloud.render(in: context.cgContext)
 //               layerLittleArrowDown.render(in: context.cgContext)
 //               layerLittleArrowUp.render(in: context.cgContext)
                break
            case IconCloudType.Completed:
                layerCloud.render(in: context.cgContext)
 //               layerValidButton.render(in: context.cgContext)
                break
            case IconCloudType.All:
                layerClouds.render(in: context.cgContext)
                layerArrows.render(in: context.cgContext)
                break
            default:
                break
            }
        }
        return img.withRenderingMode(.alwaysOriginal)
    }
    
    func frame2() -> CGRect {
        let w = frame.size.width
        let h = frame.size.height
        let _frame2 = CGRect(x: floor(w * 0.30488 + 0.5), y: floor(h * 0.50311 + 0.5), width: floor(w * 0.71341 + 0.5) - floor(w * 0.30488 + 0.5), height: floor(h * 0.86335 + 0.5) - floor(h * 0.50311 + 0.5))
        return _frame2
    }
    
    var cloudPath: CGPath {
        //static
        var path: CGPath? = nil
        layerCloud!.frame = _frame!
        if path == nil {
            let w = frame.size.width
            let h = frame.size.height
            let cloudPath = UIBezierPath()
            cloudPath.move(to: CGPoint(x: 0.24846 * w, y: 0.71086 * h))
            cloudPath.addLine(to: CGPoint(x: 0.20217 * w, y: 0.71086 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.07020 * w, y: 0.65506 * h), controlPoint1: CGPoint(x: 0.15077 * w, y: 0.71086 * h), controlPoint2: CGPoint(x: 0.10666 * w, y: 0.69226 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.01917 * w, y: 0.52041 * h), controlPoint1: CGPoint(x: 0.03375 * w, y: 0.61787 * h), controlPoint2: CGPoint(x: 0.01917 * w, y: 0.57286 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.04760 * w, y: 0.41179 * h), controlPoint1: CGPoint(x: 0.01917 * w, y: 0.47949 * h), controlPoint2: CGPoint(x: 0.02609 * w, y: 0.44303 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.13801 * w, y: 0.34148 * h), controlPoint1: CGPoint(x: 0.06911 * w, y: 0.38054 * h), controlPoint2: CGPoint(x: 0.09900 * w, y: 0.35710 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.18139 * w, y: 0.24997 * h), controlPoint1: CGPoint(x: 0.14165 * w, y: 0.30577 * h), controlPoint2: CGPoint(x: 0.15623 * w, y: 0.27527 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.27362 * w, y: 0.21240 * h), controlPoint1: CGPoint(x: 0.20654 * w, y: 0.22505 * h), controlPoint2: CGPoint(x: 0.23716 * w, y: 0.21240 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.34726 * w, y: 0.23547 * h), controlPoint1: CGPoint(x: 0.29731 * w, y: 0.21240 * h), controlPoint2: CGPoint(x: 0.32210 * w, y: 0.22021 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.44167 * w, y: 0.13057 * h), controlPoint1: CGPoint(x: 0.36986 * w, y: 0.19194 * h), controlPoint2: CGPoint(x: 0.40121 * w, y: 0.15698 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.57546 * w, y: 0.09114 * h), controlPoint1: CGPoint(x: 0.48177 * w, y: 0.10416 * h), controlPoint2: CGPoint(x: 0.52661 * w, y: 0.09114 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.75555 * w, y: 0.16628 * h), controlPoint1: CGPoint(x: 0.64582 * w, y: 0.09114 * h), controlPoint2: CGPoint(x: 0.70597 * w, y: 0.11606 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.82991 * w, y: 0.34892 * h), controlPoint1: CGPoint(x: 0.80512 * w, y: 0.21612 * h), controlPoint2: CGPoint(x: 0.82991 * w, y: 0.27713 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.82809 * w, y: 0.36045 * h), controlPoint1: CGPoint(x: 0.82991 * w, y: 0.35264 * h), controlPoint2: CGPoint(x: 0.82918 * w, y: 0.35673 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.93454 * w, y: 0.41737 * h), controlPoint1: CGPoint(x: 0.86819 * w, y: 0.36566 * h), controlPoint2: CGPoint(x: 0.90392 * w, y: 0.38463 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.98083 * w, y: 0.53380 * h), controlPoint1: CGPoint(x: 0.96516 * w, y: 0.45010 * h), controlPoint2: CGPoint(x: 0.98083 * w, y: 0.48879 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.93089 * w, y: 0.65878 * h), controlPoint1: CGPoint(x: 0.98083 * w, y: 0.58253 * h), controlPoint2: CGPoint(x: 0.96406 * w, y: 0.62419 * h))
            cloudPath.addCurve(to: CGPoint(x: 0.80913 * w, y: 0.71086 * h), controlPoint1: CGPoint(x: 0.89772 * w, y: 0.69338 * h), controlPoint2: CGPoint(x: 0.85689 * w, y: 0.71086 * h))
            cloudPath.addLine(to: CGPoint(x: 0.76976 * w, y: 0.71086 * h))
            path = cloudPath.cgPath
        }
        return path!
    }
    
    var circleArrowsPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerCircleArrows!.frame = frame2
        if path == nil {
            let w2 = frame2.size.width
            let h2 = frame2.size.height
            let circleArrowsPath = UIBezierPath()
            circleArrowsPath.move(to: CGPoint(x: 0.08687 * w2, y: 0.42079 * h2))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.49224 * w2, y: 0.02726 * h2), controlPoint1: CGPoint(x: 0.12259 * w2, y: 0.19681 * h2), controlPoint2: CGPoint(x: 0.29045 * w2, y: 0.02726 * h2))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.89760 * w2, y: 0.42079 * h2), controlPoint1: CGPoint(x: 0.69403 * w2, y: 0.02726 * h2), controlPoint2: CGPoint(x: 0.86188 * w2, y: 0.19681 * h2))
            circleArrowsPath.move(to: CGPoint(x: 0.30116 * w2, y: 0.36008 * h2))
            circleArrowsPath.addLine(to: CGPoint(x: 0.08152 * w2, y: 0.41974 * h2))
            circleArrowsPath.addLine(to: CGPoint(x: 0.03062 * w2, y: 0.16228 * h2))
            circleArrowsPath.move(to: CGPoint(x: 0.89760 * w2, y: 0.56940 * h2))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.49224 * w2, y: 0.96292 * h2), controlPoint1: CGPoint(x: 0.86188 * w2, y: 0.79338 * h2), controlPoint2: CGPoint(x: 0.69403 * w2, y: 0.96292 * h2))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.08687 * w2, y: 0.56940 * h2), controlPoint1: CGPoint(x: 0.29045 * w2, y: 0.96292 * h2), controlPoint2: CGPoint(x: 0.12259 * w2, y: 0.79338 * h2))
            circleArrowsPath.move(to: CGPoint(x: 0.68688 * w2, y: 0.66464 * h2))
            circleArrowsPath.addLine(to: CGPoint(x: 0.89760 * w2, y: 0.56940 * h2))
            circleArrowsPath.addLine(to: CGPoint(x: 0.97885 * w2, y: 0.81640 * h2))
            path = circleArrowsPath.cgPath
        }
        return path!
    }
    
    var arrowDownPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerArrowDown!.frame = frame2
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            let arrowDownPath = UIBezierPath()
            arrowDownPath.move(to: CGPoint(x: 0.49491 * w, y: 0.90623 * h))
            arrowDownPath.addLine(to: CGPoint(x: 0.49491 * w, y: 0.09178 * h))
            arrowDownPath.move(to: CGPoint(x: 0.73398 * w, y: 0.64858 * h))
            arrowDownPath.addLine(to: CGPoint(x: 0.49491 * w, y: 0.92539 * h))
            arrowDownPath.addLine(to: CGPoint(x: 0.25583 * w, y: 0.64858 * h))
            path = arrowDownPath.cgPath
        }
        return path!
    }
    
    var arrowUpPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerArrowUp!.frame = frame2
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            let arrowUpPath = UIBezierPath()
            arrowUpPath.move(to: CGPoint(x: 0.49491 * w, y: 0.11094 * h))
            arrowUpPath.addLine(to: CGPoint(x: 0.49491 * w, y: 0.92539 * h))
            arrowUpPath.move(to: CGPoint(x: 0.25583 * w, y: 0.36858 * h))
            arrowUpPath.addLine(to: CGPoint(x: 0.49491 * w, y: 0.09178 * h))
            arrowUpPath.addLine(to: CGPoint(x: 0.73398 * w, y: 0.36858 * h))
            path = arrowUpPath.cgPath
        }
        return path!
    }
    
    var validButtonPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerValidButton!.frame = frame2
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            let btnPath = UIBezierPath()
            btnPath.move(to: CGPoint(x: 0.20099 * w, y: 0.55099 * h))
            btnPath.addLine(to: CGPoint(x: 0.50299 * w, y: 0.90099 * h))
            btnPath.addLine(to: CGPoint(x: 0.85099 * w, y: 0.15079 * h))
            path = btnPath.cgPath
        }
        return path!
    }
    
    var waitButtonPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerWaitButton!.frame = frame2
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            //let btnPath = UIBezierPath()
            
            let circleArrowsPath = UIBezierPath()
            circleArrowsPath.move(to: CGPoint(x: 0.08687 * w, y: 0.42079 * h))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.49224 * w, y: 0.02726 * h), controlPoint1: CGPoint(x: 0.12259 * w, y: 0.19681 * h), controlPoint2: CGPoint(x: 0.29045 * w, y: 0.02726 * h))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.89760 * w, y: 0.42079 * h), controlPoint1: CGPoint(x: 0.69403 * w, y: 0.02726 * h), controlPoint2: CGPoint(x: 0.86188 * w, y: 0.19681 * h))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.49224 * w, y: 0.96292 * h), controlPoint1: CGPoint(x: 0.86188 * w, y: 0.79338 * h), controlPoint2: CGPoint(x: 0.69403 * w, y: 0.96292 * h))
            circleArrowsPath.addCurve(to: CGPoint(x: 0.08687 * w, y: 0.56940 * h), controlPoint1: CGPoint(x: 0.29045 * w, y: 0.96292 * h), controlPoint2: CGPoint(x: 0.12259 * w, y: 0.79338 * h))
            circleArrowsPath.close()
            circleArrowsPath.move(to: CGPoint(x: 0.5 * w, y: 0.5 * h))
            circleArrowsPath.addLine(to: CGPoint(x: 0.66099 * w, y: 0.33099 * h))
            path = circleArrowsPath.cgPath
           
        }
        return path!
    }
    
    var waitArrowPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerWaitArrow!.frame = frame2
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            let btnPath = UIBezierPath()
            btnPath.move(to: CGPoint(x: 0.35099 * w, y: 0.5 * h))
            btnPath.addLine(to: CGPoint(x: 0.5 * w, y: 0.5 * h))
            path = btnPath.cgPath
        }
        return path!
    }
    
    var stopButtonPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerStopButton!.frame = frame2
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            let btnPath = UIBezierPath()
            btnPath.move(to: CGPoint(x: 0.90299 * w, y: 0.50431 * h))
            btnPath.addCurve(to: CGPoint(x: 0.49627 * w, y: 0.03448 * h), controlPoint1: CGPoint(x: 0.90299 * w, y: 0.24483 * h), controlPoint2: CGPoint(x: 0.72089 * w, y: 0.03448 * h))
            btnPath.addCurve(to: CGPoint(x: 0.08955 * w, y: 0.50431 * h), controlPoint1: CGPoint(x: 0.27165 * w, y: 0.03448 * h), controlPoint2: CGPoint(x: 0.08955 * w, y: 0.24483 * h))
            btnPath.addCurve(to: CGPoint(x: 0.49627 * w, y: 0.97414 * h), controlPoint1: CGPoint(x: 0.08955 * w, y: 0.76379 * h), controlPoint2: CGPoint(x: 0.27165 * w, y: 0.97414 * h))
            btnPath.addCurve(to: CGPoint(x: 0.90299 * w, y: 0.50431 * h), controlPoint1: CGPoint(x: 0.72089 * w, y: 0.97414 * h), controlPoint2: CGPoint(x: 0.90299 * w, y: 0.76379 * h))
            btnPath.close()
            btnPath.move(to: CGPoint(x: 0.40299 * w, y: 0.37069 * h))
            btnPath.addLine(to: CGPoint(x: 0.40299 * w, y: 0.66379 * h))
            btnPath.move(to: CGPoint(x: 0.56716 * w, y: 0.37069 * h))
            btnPath.addLine(to: CGPoint(x: 0.56716 * w, y: 0.66379 * h))
            path = btnPath.cgPath
        }
        return path!
    }
    
    var crossButtonPath: CGPath {
        //static
        var path: CGPath? = nil
        let frame2 = self.frame2()
        layerCrossButton!.frame = frame2
        if path == nil {
            let w = frame2.size.width
            let h = frame2.size.height
            let errPath = UIBezierPath()
            errPath.move(to: CGPoint(x: 0.79468 * w, y: 0.82354 * h))
            errPath.addCurve(to: CGPoint(x: 0.90299 * w, y: 0.50431 * h), controlPoint1: CGPoint(x: 0.86190 * w, y: 0.73973 * h), controlPoint2: CGPoint(x: 0.90299 * w, y: 0.62757 * h))
            errPath.addCurve(to: CGPoint(x: 0.49627 * w, y: 0.03448 * h), controlPoint1: CGPoint(x: 0.90299 * w, y: 0.24483 * h), controlPoint2: CGPoint(x: 0.72089 * w, y: 0.03448 * h))
            errPath.addCurve(to: CGPoint(x: 0.08955 * w, y: 0.50431 * h), controlPoint1: CGPoint(x: 0.27165 * w, y: 0.03448 * h), controlPoint2: CGPoint(x: 0.08955 * w, y: 0.24483 * h))
            errPath.addCurve(to: CGPoint(x: 0.49627 * w, y: 0.97414 * h), controlPoint1: CGPoint(x: 0.08955 * w, y: 0.76379 * h), controlPoint2: CGPoint(x: 0.27165 * w, y: 0.97414 * h))
            errPath.addCurve(to: CGPoint(x: 0.79468 * w, y: 0.82354 * h), controlPoint1: CGPoint(x: 0.61419 * w, y: 0.97414 * h), controlPoint2: CGPoint(x: 0.72040 * w, y: 0.91616 * h))
            errPath.close()
            errPath.move(to: CGPoint(x: 0.34018 * w, y: 0.32990 * h))
            errPath.addLine(to: CGPoint(x: 0.64624 * w, y: 0.68345 * h))
            errPath.move(to: CGPoint(x: 0.35075 * w, y: 0.68345 * h))
            errPath.addLine(to: CGPoint(x: 0.65681 * w, y: 0.32990 * h))
            path = errPath.cgPath
        }
        return path!
    }
    
    var littleArrowUpPath: CGPath {
        let w = _frame!.size.width
        let h = _frame!.size.height
        let arrUpPath = UIBezierPath()
        arrUpPath.move(to: CGPoint(x: 0.45200 * w, y: 0.50074 * h))
        arrUpPath.addLine(to: CGPoint(x: 0.45200 * w, y: 0.78513 * h))
        arrUpPath.move(to: CGPoint(x: 0.35745 * w, y: 0.59071 * h))
        arrUpPath.addLine(to: CGPoint(x: 0.45200 * w, y: 0.49405 * h))
        arrUpPath.addLine(to: CGPoint(x: 0.54655 * w, y: 0.59071 * h))
        layerLittleArrowUp!.frame = _frame!
        return arrUpPath.cgPath
    }
    
    var littleArrowDownPath: CGPath {
        let w = _frame!.size.width
        let h = _frame!.size.height
        let arrDownPath = UIBezierPath()
        arrDownPath.move(to: CGPoint(x: 0.61200 * w, y: 0.87026 * h))
        arrDownPath.addLine(to: CGPoint(x: 0.61200 * w, y: 0.58587 * h))
        arrDownPath.move(to: CGPoint(x: 0.70655 * w, y: 0.78030 * h))
        arrDownPath.addLine(to: CGPoint(x: 0.61200 * w, y: 0.87695 * h))
        arrDownPath.addLine(to: CGPoint(x: 0.51745 * w, y: 0.78030 * h))
        layerLittleArrowDown!.frame = _frame!
        return arrDownPath.cgPath
    }
    
    var cloudsPath: CGPath {
        let w = _frame!.size.width
        let h = _frame!.size.height
        let cloudsPath = UIBezierPath()
        cloudsPath.move(to: CGPoint(x: 0.44914 * w, y: 0.74233 * h))
        cloudsPath.addLine(to: CGPoint(x: 0.33726 * w, y: 0.74233 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.23247 * w, y: 0.69888 * h), controlPoint1: CGPoint(x: 0.29627 * w, y: 0.74233 * h), controlPoint2: CGPoint(x: 0.26144 * w, y: 0.72785 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.18901 * w, y: 0.59408 * h), controlPoint1: CGPoint(x: 0.20350 * w, y: 0.66990 * h), controlPoint2: CGPoint(x: 0.18901 * w, y: 0.63507 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.23247 * w, y: 0.48929 * h), controlPoint1: CGPoint(x: 0.18901 * w, y: 0.55309 * h), controlPoint2: CGPoint(x: 0.20350 * w, y: 0.51826 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.33726 * w, y: 0.44583 * h), controlPoint1: CGPoint(x: 0.26144 * w, y: 0.46032 * h), controlPoint2: CGPoint(x: 0.29627 * w, y: 0.44583 * h))
        cloudsPath.addLine(to: CGPoint(x: 0.33726 * w, y: 0.43566 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.39428 * w, y: 0.29851 * h), controlPoint1: CGPoint(x: 0.33757 * w, y: 0.38203 * h), controlPoint2: CGPoint(x: 0.35668 * w, y: 0.33642 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.53082 * w, y: 0.24149 * h), controlPoint1: CGPoint(x: 0.43219 * w, y: 0.26059 * h), controlPoint2: CGPoint(x: 0.47781 * w, y: 0.24149 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.64918 * w, y: 0.28032 * h), controlPoint1: CGPoint(x: 0.57551 * w, y: 0.24149 * h), controlPoint2: CGPoint(x: 0.61496 * w, y: 0.25443 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.71883 * w, y: 0.38234 * h), controlPoint1: CGPoint(x: 0.68339 * w, y: 0.30621 * h), controlPoint2: CGPoint(x: 0.70681 * w, y: 0.34042 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.78202 * w, y: 0.37155 * h), controlPoint1: CGPoint(x: 0.74041 * w, y: 0.37525 * h), controlPoint2: CGPoint(x: 0.76167 * w, y: 0.37155 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.91208 * w, y: 0.42580 * h), controlPoint1: CGPoint(x: 0.83256 * w, y: 0.37155 * h), controlPoint2: CGPoint(x: 0.87602 * w, y: 0.38974 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.96633 * w, y: 0.55679 * h), controlPoint1: CGPoint(x: 0.94814 * w, y: 0.46186 * h), controlPoint2: CGPoint(x: 0.96633 * w, y: 0.50562 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.91208 * w, y: 0.68778 * h), controlPoint1: CGPoint(x: 0.96633 * w, y: 0.60795 * h), controlPoint2: CGPoint(x: 0.94814 * w, y: 0.65172 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.78202 * w, y: 0.74202 * h), controlPoint1: CGPoint(x: 0.87602 * w, y: 0.72384 * h), controlPoint2: CGPoint(x: 0.83256 * w, y: 0.74202 * h))
        cloudsPath.addLine(to: CGPoint(x: 0.69078 * w, y: 0.74202 * h))
        cloudsPath.move(to: CGPoint(x: 0.45932 * w, y: 0.22762 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.44082 * w, y: 0.21128 * h), controlPoint1: CGPoint(x: 0.45346 * w, y: 0.22176 * h), controlPoint2: CGPoint(x: 0.44760 * w, y: 0.21621 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.33665 * w, y: 0.17707 * h), controlPoint1: CGPoint(x: 0.41062 * w, y: 0.18847 * h), controlPoint2: CGPoint(x: 0.37579 * w, y: 0.17707 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.21644 * w, y: 0.22731 * h), controlPoint1: CGPoint(x: 0.28980 * w, y: 0.17707 * h), controlPoint2: CGPoint(x: 0.24973 * w, y: 0.19371 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.16620 * w, y: 0.34905 * h), controlPoint1: CGPoint(x: 0.18316 * w, y: 0.26090 * h), controlPoint2: CGPoint(x: 0.16620 * w, y: 0.30128 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.16929 * w, y: 0.35707 * h), controlPoint1: CGPoint(x: 0.16620 * w, y: 0.35306 * h), controlPoint2: CGPoint(x: 0.16744 * w, y: 0.35552 * h))
        cloudsPath.addLine(to: CGPoint(x: 0.16620 * w, y: 0.35707 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.07374 * w, y: 0.39528 * h), controlPoint1: CGPoint(x: 0.13014 * w, y: 0.35707 * h), controlPoint2: CGPoint(x: 0.09932 * w, y: 0.36970 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.03552 * w, y: 0.48775 * h), controlPoint1: CGPoint(x: 0.04816 * w, y: 0.42087 * h), controlPoint2: CGPoint(x: 0.03552 * w, y: 0.45169 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.07374 * w, y: 0.58021 * h), controlPoint1: CGPoint(x: 0.03552 * w, y: 0.52381 * h), controlPoint2: CGPoint(x: 0.04816 * w, y: 0.55463 * h))
        cloudsPath.addCurve(to: CGPoint(x: 0.16620 * w, y: 0.61843 * h), controlPoint1: CGPoint(x: 0.09932 * w, y: 0.60579 * h), controlPoint2: CGPoint(x: 0.12984 * w, y: 0.61843 * h))
        cloudsPath.addLine(to: CGPoint(x: 0.16929 * w, y: 0.61843 * h))
        layerClouds!.frame = _frame!
        return cloudsPath.cgPath
    }
    
    var arrowsPath:CGPath {
        let w = _frame!.size.width
        let h = _frame!.size.height
        let arrowsPath = UIBezierPath()
        arrowsPath.move(to: CGPoint(x: 0.62298 * w, y: 0.58977 * h))
        arrowsPath.addLine(to: CGPoint(x: 0.62298 * w, y: 0.77346 * h))
        arrowsPath.move(to: CGPoint(x: 0.56103 * w, y: 0.64788 * h))
        arrowsPath.addLine(to: CGPoint(x: 0.62298 * w, y: 0.58545 * h))
        arrowsPath.addLine(to: CGPoint(x: 0.68493 * w, y: 0.64788 * h))
        arrowsPath.move(to: CGPoint(x: 0.52065 * w, y: 0.86469 * h))
        arrowsPath.addLine(to: CGPoint(x: 0.52065 * w, y: 0.68100 * h))
        arrowsPath.move(to: CGPoint(x: 0.58260 * w, y: 0.80658 * h))
        arrowsPath.addLine(to: CGPoint(x: 0.52065 * w, y: 0.86901 * h))
        arrowsPath.addLine(to: CGPoint(x: 0.45870 * w, y: 0.80658 * h))
        layerArrows!.frame = _frame!
        return arrowsPath.cgPath
    }
    
}
