//
//  TorrentCommonController.swift
//  Transmission Remote
//
//  Created by  on 12/13/19.
//

import Cocoa
import TransmissionRPC

public class TorrentCommonController: NSViewController {

    @objc dynamic public var torrentDetailsController: TorrentDetailsController!
    
    private static var observerContext = 0
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override public func viewWillAppear() {
        super.viewWillAppear()

    }

}
