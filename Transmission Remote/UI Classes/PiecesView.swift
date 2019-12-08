//
//  PiecesView.swift
//  Transmission Remote
//
//  Created by  on 7/21/19.
//

import UIKit
import os

class PiecesView: UIView {
    var count:Int  = 0
    var rows: Int?
    var cols: Int?
    var bits: NSData?
    var prevbits: NSData?
    var pw: CGFloat = 0.0
    var ph: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        
        if bits == nil {
            return
        }
        
        let cFilled = UIColor(displayP3Red: 0, green: 0.5, blue: 0, alpha: 1.0)
        let cEmpty = UIColor(displayP3Red: 29.0/255.0, green: 151.0/255.0, blue: 1.0, alpha: 1.0)
        UIColor.white.setStroke()
        
            
            var pb = bits!.bytes
            var prevb: UInt8? = nil //_prevbits ? (uint8_t*)_prevbits.bytes : NULL;
            
            let maxc = count
            var shift = 0
            
            for i in 0..<maxc {
                let col = i % (cols ?? 1)
                let row = i / (cols ?? 1)//- row * _cols;
                
                //NSLog(@"[%i,%i] - %i", row, col, i);
                
                let c = pb.load(as: UInt8.self)
                let filled = ((Int(c) >> shift) & 0x1) != 0 ? true : false
                var needAnimate = false
                if prevb != nil {
                    let prevc = prevb!
                    let prevfilled = ((Int(prevc) >> shift) & 0x1) != 0 ? true : false
                    needAnimate = prevfilled != filled
                }
                
                shift += 1
                if shift > 7 {
                    shift = 0
                    pb += 1
                    
                    if prevb != nil {
                        prevb! += 1
                    }
                }
                
                // draw legend block
                let path = UIBezierPath(rect: CGRect(x: CGFloat(col) * pw + 1, y: CGFloat(row) * ph + 1, width: pw - 1, height: ph - 1))
                filled ? cFilled.setFill() : cEmpty.setFill()
                if needAnimate {
                    os_log("Need animate piece")
                    
                    let layer = CAShapeLayer()
                    layer.path = path.cgPath
                    layer.fillColor = cEmpty.cgColor
                    layer.lineWidth = 0
                    self.layer.addSublayer(layer)
                    
                    let anim = CABasicAnimation(keyPath: "fillColor")
                    anim.duration = 1.0
                    anim.toValue = cFilled.cgColor
                    anim.timeOffset = 0.3
                    
                    layer.add(anim, forKey: nil)
                } else {
                    path.fill()
                }
        }
    }
    
}

