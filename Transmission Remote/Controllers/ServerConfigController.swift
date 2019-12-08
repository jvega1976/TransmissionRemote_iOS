//
//  RPCServerConfigController.swift
//  Transmission Remote
//
//  Created by  on 7/17/19.
//

import UIKit

class ServerConfigController: CommonTableController {
    
    @IBOutlet private weak var iconServerName: UIImageView!
    @IBOutlet private weak var labelServerName: UILabel!
    @IBOutlet private weak var textServerName: UITextField!
    @IBOutlet weak var iconDefaultServer: UIImageView!
    @IBOutlet weak var labelDefaultServer: UILabel!
    @IBOutlet weak var switchDefaultServer: UISwitch!
    
    // RPC SETTINGS
    @IBOutlet private weak var iconHost: UIImageView!
    @IBOutlet private weak var labelHost: UILabel!
    @IBOutlet private weak var textHost: UITextField!
    @IBOutlet private weak var iconPort: UIImageView!
    @IBOutlet private weak var labelPort: UILabel!
    @IBOutlet private weak var textPort: UITextField!
    @IBOutlet private weak var iconRPCPath: UIImageView!
    @IBOutlet private weak var labelRPCPath: UILabel!
    @IBOutlet private weak var textRPCPath: UITextField!
    // SECURITY SETTINGS
    @IBOutlet private weak var iconUserName: UIImageView!
    @IBOutlet private weak var labelUserName: UILabel!
    @IBOutlet private weak var textUserName: UITextField!
    @IBOutlet private weak var iconUserPassword: UIImageView!
    @IBOutlet private weak var labelUserPassword: UILabel!
    @IBOutlet private weak var textUserPassword: UITextField!
    @IBOutlet private weak var iconUseSSL: UIImageView!
    @IBOutlet private weak var labelUseSSL: UILabel!
    @IBOutlet private weak var switchUseSSL: UISwitch!
    // TIMEOUT SETTINGS
    @IBOutlet private weak var iconRefreshTimeout: UIImageView!
    @IBOutlet private weak var labelRefreshTimeout: UILabel!
    @IBOutlet private weak var labelRefreshTimeoutNumber: UILabel!
    @IBOutlet private weak var stepperRefreshTimeout: UIStepper!
    @IBOutlet private weak var iconRequestTimeout: UIImageView!
    @IBOutlet private weak var labelRequestTimeout: UILabel!
    @IBOutlet private weak var labelRequestTimeoutNumber: UILabel!
    @IBOutlet private weak var stepperRequestTimeout: UIStepper!
    // MISC
    @IBOutlet private weak var switchShowFreeSpace: UISwitch!
    @IBOutlet private weak var iconShowFreeSpace: UIImageView!
    
    var  config:RPCServerConfig!
    
    var  serverListController: ServerListController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initIcons()
        loadConfig()
    }
    
    func initIcons() {
        let arr = [
            iconServerName,
            iconDefaultServer,
            iconHost,
            iconPort,
            iconRPCPath,
            iconUserName,
            iconUserPassword,
            iconUseSSL,
            iconRefreshTimeout,
            iconRequestTimeout,
            iconShowFreeSpace
        ]

        for iv in arr {
            iv!.image = iv!.image!.withRenderingMode(.alwaysTemplate)
        }
    }
    
    func trimString(_ string: String?) -> String? {
        return string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    // MARK: - utility methods
    
    // update values from config
    func loadConfig() {

        // loading values
        if (config != nil){
            textServerName.text = config.name
            switchDefaultServer.isOn = config.defaultServer
            textHost.text = config.host
            textPort.text = "\(config.port)"
            textRPCPath.text = config.rpcPath
            
            textUserName.text = config.userName
            textUserPassword.text = config.userPassword
            switchUseSSL.isOn = config.useSSL
            
            stepperRefreshTimeout.value = Double(config.refreshTimeout)
            stepperRequestTimeout.value = Double(config.requestTimeout)
            
            switchShowFreeSpace.isOn = config.showFreeSpace
        }
        
        stepperRefreshTimeout.sendActions(for: .valueChanged)
        stepperRequestTimeout.sendActions(for: .valueChanged)
    }
    
    func showRowError(_ errorMessage: String?, icon iconImg: UIImageView?, label: UILabel?, textControl: UITextField?) {
        let errColor = UIColor.red
        let normalColor = UIColor.black
        
        if errorMessage != nil {
            //self.errorMessage = errorMessage;
            label?.textColor = errColor
            iconImg?.tintColor = errColor
            
            if textControl != nil {
                textControl?.becomeFirstResponder()
            }
        } else {
            label?.textColor = normalColor
            iconImg?.tintColor = tableView.tintColor
        }
    }
    
    @IBAction func saveConfig(_ sender: UIBarButtonItem ) {
        // if server config is not
        // set, it means that we create new serve config
        // and should return this config
        if (config == nil) {
            config = RPCServerConfig()
        }
        
        var errString = ""
        var success = true
        
        var serverName = ""
        var host = ""
        var rpcPath = ""
        
        var str = trimString(textServerName.text)
        
        if (str?.count ?? 0) < 1 {
            errString += NSLocalizedString("You should enter server NAME\n", comment: "RPCServerConfig error message")
            showRowError(errString, icon: iconServerName, label: labelServerName, textControl: textServerName)
            
            success = false
        } else {
            showRowError(nil, icon: iconServerName, label: labelServerName, textControl: nil)
            serverName = str ?? ""
        }
        
        str = trimString(textHost.text)
        if (str?.count ?? 0) < 1 {
            errString += NSLocalizedString("You should enter server HOST name\n", comment: "RPCServerConfig error message")
            showRowError(errString, icon: iconHost, label: labelHost, textControl: textHost)
            
            success = false
        } else {
            showRowError(nil, icon: iconHost, label: labelHost, textControl: nil)
            host = str ?? ""
        }
        
        
        let port = Int(trimString(textPort.text) ?? "") ?? 0
        
        if port <= 0 || port > 65535 {
            errString += NSLocalizedString("Server port must be in range from 0 to 65535. By default server port number is 8090\n", comment: "RPCServerConfig error message")
            showRowError(errString, icon: iconPort, label: labelPort, textControl: textPort)
            success = false
        } else {
            showRowError(nil, icon: iconPort, label: labelPort, textControl: nil)
        }
        
        str = trimString(textRPCPath.text)
        if (str?.count ?? 0) < 1 {
            errString += NSLocalizedString("You should enter server RPC path. By default server rpc path is /transmission/rpc", comment: "RPCServerConfig error message")
            showRowError(errString, icon: iconRPCPath, label: labelRPCPath, textControl: textRPCPath)
            success = false
        } else {
            showRowError(nil, icon: iconRPCPath, label: labelRPCPath, textControl: nil)
            rpcPath = str ?? ""
        }
        
        if !success {
            errorMessage = errString
            return
            //Add Alert Error         errorMessage = errString
        }
        // when all values is ok, save config
        config.port = port
        config.host = host
        config.name = serverName
        config.defaultServer = switchDefaultServer.isOn
        config.rpcPath = rpcPath
        
        config.userName = trimString(textUserName.text) ?? ""
        config.userPassword = trimString(textUserPassword.text) ?? ""
        config.useSSL = switchUseSSL.isOn
        
        config.refreshTimeout = stepperRefreshTimeout.value
        config.requestTimeout = stepperRequestTimeout.value
        
        config.showFreeSpace = switchShowFreeSpace.isOn
        
        serverListController.tableView.beginUpdates()
        var indexPaths: [IndexPath]! = []
        
        if config.defaultServer {
            if ServerConfigDB.shared.db.contains(where: {$0.defaultServer && $0.name != config.name}) {
                let index = ServerConfigDB.shared.db.firstIndex(where: {$0.defaultServer && $0.name != config.name})
                ServerConfigDB.shared.db[index!].defaultServer = false
                indexPaths.append(IndexPath(row: index!, section: 0))
            }
        }
        if let index = ServerConfigDB.shared.db.firstIndex(of: config) {
            ServerConfigDB.shared.db[index] = config
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        else {
            ServerConfigDB.shared.db.append(config)
            let indexPath = IndexPath(item: serverListController.serverConfigs.lastIndex(of: config)!, section: 0)
            serverListController.tableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
        if indexPaths != [] {
            serverListController.tableView.reloadRows(at: indexPaths, with: UITableView.RowAnimation.automatic)
        }
        ServerConfigDB.shared.save()
        serverListController.tableView.endUpdates()
        navigationController?.popViewController(animated: true)
        //Add Alert Error
    }
    
    
    @IBAction func requestTimeoutValueChagned(_ sender: UIStepper) {
        labelRequestTimeoutNumber.text = String(format: "%02i", Int(sender.value))
    }
    
    
    @IBAction func refreshTimoutValueChanged(_ sender: UIStepper) {
        if sender.value == 0 {
            labelRefreshTimeoutNumber.text = NSLocalizedString("OFF", comment: "RPCServerConfig timeouf message is OFF")
        } else {
            labelRefreshTimeoutNumber.text = String(format: "%02i", Int(sender.value))
        }
    }
    
    @IBAction func validateDefaultServer(_ sender: UISwitch) {
        if sender.isOn {
            var index_old: Int! = NSNotFound
            var indexPaths: [IndexPath]! = []
            if ServerConfigDB.shared.db.contains(where: {$0.defaultServer }) {
                index_old = ServerConfigDB.shared.db.firstIndex(where: {$0.defaultServer })
                ServerConfigDB.shared.db[index_old].defaultServer = false
                indexPaths.append(IndexPath(row: index_old, section: 0))
            }
            if let index = ServerConfigDB.shared.db.firstIndex(of: config) {
                ServerConfigDB.shared.db[index] = config
                indexPaths.append(IndexPath(row: index, section: 0))
            }
            ServerConfigDB.shared.save()
            serverListController.tableView.reloadRows(at: indexPaths, with: UITableView.RowAnimation.automatic)
        }
    }
    
}
