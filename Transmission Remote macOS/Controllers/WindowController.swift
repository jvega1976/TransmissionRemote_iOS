//
//  WindowController.swift
//  Transmission Remote
//
//  Created by  on 12/20/19.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
  
    
    
  
    override func shouldPerformSegue(withIdentifier identifier: NSStoryboardSegue.Identifier, sender: Any?) -> Bool {
        switch identifier {
            case "serverConfigList":
                guard let segmentedControl = sender as? NSSegmentedControl else {return false }
                let pushedSegment = segmentedControl.selectedTag()
                return pushedSegment == 0
            case "filterStatus":
                guard let button = sender as? NSToolbarItem else {return false }
                return button.label == "Filter"
            default: return true
        }
    }
    
    

}
