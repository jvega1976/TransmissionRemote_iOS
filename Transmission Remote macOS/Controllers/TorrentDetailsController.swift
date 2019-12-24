//
//  TorrentDetailsController.swift
//  Transmission Remote
//
//  Created by  on 12/13/19.
//

import Cocoa
import TransmissionRPC
import Categorization

public class TorrentDetailsController: NSTabViewController {
    
    var mainController: MainViewController!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        for childController in self.children {
            if let childController = childController as? TorrentFilesController {
                mainController.torrentFilesController = childController
            }
        }
        self.selectedTabViewItemIndex = 4
    }
    
    override public func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let controller = segue.destinationController as? TorrentCommonController else { return }
        controller.view.frame = self.view.bounds
        controller.view.needsDisplay = true
    }
    
}
