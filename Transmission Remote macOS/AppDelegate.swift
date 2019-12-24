//
//  AppDelegate.swift
//  Transmission Remote macOS
//
//  Created by  on 12/10/19.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let index = NSApp.mainWindow?.toolbar?.visibleItems?.firstIndex(where:{item in
            item.itemIdentifier == NSToolbarItem.Identifier("sortFiles")}) {
            NSApp.mainWindow?.toolbar?.removeItem(at: index)
            if NSApp.mainWindow?.toolbar?.visibleItems?.last?.itemIdentifier ==  NSToolbarItem.Identifier.space {
                NSApp.mainWindow?.toolbar?.removeItem(at: NSApp.mainWindow!.toolbar!.visibleItems!.count - 1)
            }
        }
        if let index = NSApp.mainWindow?.toolbar?.visibleItems?.firstIndex(where:{item in
            item.itemIdentifier == NSToolbarItem.Identifier("searchFiles")}) {
            NSApp.mainWindow?.toolbar?.removeItem(at: index)
            if NSApp.mainWindow?.toolbar?.visibleItems?.last?.itemIdentifier ==  NSToolbarItem.Identifier.space {
                NSApp.mainWindow?.toolbar?.removeItem(at: NSApp.mainWindow!.toolbar!.visibleItems!.count - 1)
            }
        }
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application

    }


}

