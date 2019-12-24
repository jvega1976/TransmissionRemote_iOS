//
//  ViewController.swift
//  Transmission Remote macOS
//
//  Created by  on 12/10/19.
//

import Cocoa

public class ServerConfigController: NSViewController {

    @objc dynamic public var serverConfigList: [RPCServerConfig] {
        get {
            return ServerConfigDB.shared.db
        }
        set(newList) {
            ServerConfigDB.shared.db = newList
        }
    }
        
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func finishServerConfigSetup(_ sender: NSButton) {
        ServerConfigDB.shared.save()
        self.dismiss(self)
    }

}

