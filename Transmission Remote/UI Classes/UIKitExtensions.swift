//
//  AppKitExtensions.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

import UIKit

extension UIColor {
    class var colorDownload: UIColor? {
        //return UIColor(named: "DownloadColor")
        return UIColor.systemGreen
    }

    class var colorAll: UIColor? {
        //return UIColor.lightGray
        return UIColor(named: "AllColor")
    }

    class var colorError: UIColor? {
        //return UIColor(named: "ErrorColor")
        return UIColor.red
    }

    class var colorUpload: UIColor? {
        return UIColor(named: "UploadColor")
        //return UIColor.systemPurple
    }

    class var colorActive: UIColor? {
        return UIColor(named: "ActiveColor")
        //return UIColor.orange
    }

    class var colorCompleted: UIColor? {
        return UIColor.systemBlue
    }

    class var colorWait: UIColor? {
        return UIColor(named: "WaitColor1")
        //return UIColor.systemTeal
    }

    class var colorVerify: UIColor? {
        //return UIColor(named: "VerifyColor")
        return UIColor(named: "StopColor")
    }

    class var colorPaused: UIColor? {
        //return UIColor(named: "StopColor")
        return UIColor.systemGray
    }

    class var progressBarTrack: UIColor? {
        return UIColor(named: "ProgressBarTrackColor")
    }
}
