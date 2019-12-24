//
//  MasterViewController.swift
//  Transmission Remote
//
//  Created by  on 7/10/19.
//

import UIKit
import Categorization
import TransmissionRPC

class ServerListController: CommonTableController {
    
    var torrentListController: TorrentListController!
    
    var serverConfigs: [RPCServerConfig] {
        set(newServerConfigs) {
            ServerConfigDB.shared.db = newServerConfigs
        }
        get {
            return ServerConfigDB.shared.db
        }
    }


    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = editButtonItem
        clearsSelectionOnViewWillAppear = true
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus.circle"), style: .plain, target: self, action: #selector(addNewConfig(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }

    
    @objc
    @IBAction func addNewConfig(_ sender: UIBarButtonItem) {
        RPCServerConfig.sharedConfig = RPCServerConfig()
        performSegue(withIdentifier: "EditServerConfig", sender: self)

    }
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTorrentList" {
            torrentListController = (segue.destination as! TorrentListController)
            torrentListController.session = RPCSession.shared
            torrentListController.navigationItem.leftItemsSupplementBackButton = true
        }
        else if segue.identifier == "EditServerConfig" {
            let serverConfigController = segue.destination as! ServerConfigController
            serverConfigController.serverListController = self;
            serverConfigController.config = RPCServerConfig.sharedConfig
        }
    }
    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "EditServerConfig" && isEditing {
            return true
        }
        else if identifier == "showTorrentList" {
            if !isEditing {
                guard let indexPath = tableView.indexPathForSelectedRow else { return false }
                RPCServerConfig.sharedConfig = serverConfigs[indexPath.row]
                do {
                    RPCServerConfig.sharedConfig = serverConfigs[indexPath.row]
                    RPCSession.shared = try RPCSession(withURL: RPCServerConfig.sharedConfig!.configURL!, andTimeout: RPCServerConfig.sharedConfig!.requestTimeout)
                } catch {
                    displayErrorMessage(error.localizedDescription, using: self)
                    return false
                }
                return true
            } else {
                return false
            }
        }
        else {
            return false
        }
    }

    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverConfigs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ServerListCell = tableView.dequeueReusableCell(withIdentifier: "ServerListCell", for: indexPath) as! ServerListCell
        
        let serverConfig = serverConfigs[indexPath.row]
        cell.serverName.text = serverConfig.name
        cell.serverURL.text = serverConfig.urlString
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            serverConfigs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            ServerConfigDB.shared.save()
        }
    }
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        RPCServerConfig.sharedConfig = serverConfigs[indexPath.row]
        if self.isEditing {
            performSegue(withIdentifier: "EditServerConfig", sender: self)
        }
    }

}

