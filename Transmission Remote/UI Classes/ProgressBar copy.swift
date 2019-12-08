//
//  ProgressBar.swift
//  Transmission Remote
//
//  Created by  on 7/26/19.
//

import UIKit

//
//  PiecesView.swift
//  Transmission Remote
//
//  Created by  on 7/21/19.
//

import UIKit

class ProgressBar: UIView {

    var _progress: CGFloat = 0.0
    var progressColor: UIColor = UIColor.systemGreen
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var progress:Float!  {
        set(newProgress) {
            _progress = CGFloat(newProgress)
            self.setNeedsDisplay()
        }
        get {
            return Float(_progress)
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        let bar =  UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.size.width * _progress, height: self.frame.size.width))
        progressColor.setFill()
        bar.fill()
    }
    
}

