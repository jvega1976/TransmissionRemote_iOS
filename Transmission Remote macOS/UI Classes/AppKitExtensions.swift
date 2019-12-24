//
//  AppKitExtensions.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

import AppKit

extension NSColor {
    class var colorDownload: NSColor {
        //return NSColor(named: "DownloadColor")
        return NSColor.systemGreen
    }

    class var colorAll: NSColor? {
        //return NSColor.lightGray
        return NSColor(named: "AllColor")
    }

    class var colorError: NSColor {
        //return NSColor(named: "ErrorColor")
        return NSColor.red
    }

    class var colorUpload: NSColor? {
        return NSColor(named: "UploadColor")
        //return NSColor.systemPurple
    }

    class var colorActive: NSColor? {
        return NSColor(named: "ActiveColor")
        //return NSColor.orange
    }

    class var colorCompleted: NSColor {
        return NSColor.systemBlue
    }

    class var colorWait: NSColor? {
        return NSColor(named: "WaitColor1")
        //return NSColor.systemTeal
    }

    class var colorVerify: NSColor? {
        //return NSColor(named: "VerifyColor")
        return NSColor(named: "StopColor")
    }

    class var colorPaused: NSColor {
        //return NSColor(named: "StopColor")
        return NSColor.systemGray
    }

    class var progressBarTrack: NSColor? {
        return NSColor(named: "ProgressBarTrackColor")
    }
}

public class MyNSView: NSView {
    
    @objc dynamic public override var isFlipped: Bool {
        return true
    }
}
