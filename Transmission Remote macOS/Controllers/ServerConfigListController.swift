//
//  ServerConfigListController.swift
//  Transmission Remote
//
//  Created by  on 12/20/19.
//

import Cocoa

class ServerConfigListController: NSViewController,
                                  NSTableViewDataSource,
                                  NSTableViewDelegate
{

    @objc dynamic public var serverConfigList: [RPCServerConfig] = {
        return ServerConfigDB.shared.db
    }()
    
    @objc dynamic public var serverConfig: RPCServerConfig? {
        return RPCServerConfig.sharedConfig
    }
    
    @IBOutlet @objc dynamic var serverConfigArrayController: NSArrayController!
    
    @IBOutlet weak var serverConfigTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.serverConfigTableView.reloadData()
    }
    
// MARK: - TableView DataSource Protocol
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let config = serverConfigArrayController.selectedObjects.first as? RPCServerConfig else { return }
        RPCServerConfig.sharedConfig = config
        NotificationCenter.default.post(name: .ServerConfigChanged, object: self)
    }
}


extension Notification.Name {
    static let ServerConfigChanged = Notification.Name(rawValue: "ServerConfigChanged")
}
