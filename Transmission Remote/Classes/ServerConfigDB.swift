//
//  ServerConfigDB.swift
//  Transmission Remote
//
//  Created by Alexey Chechetkin on 24.06.15.
//  Copyright (c) 2015 Alexey Chechetkin. All rights reserved.
//
// singlton for getting rpc data config
import Foundation
import os

let TR_URL_DEFAULTS = "TransmissionRemote"
let TR_URL_CONFIG_KEY = "URLConfigDB"
let TR_URL_ACTUAL_KEY = "ActualURL"
let TR_URL_CONFIG_NAME = "name"
let TR_URL_CONFIG_HOST = "host"
let TR_URL_CONFIG_PORT = "port"
let TR_URL_CONFIG_USER = "userName"
let TR_URL_CONFIG_PASS = "userPassword"
let TR_URL_CONFIG_SSL = "useSSL"
let TR_URL_CONFIG_AUTH = "requireAuth"
let TR_URL_CONFIG_SVR = "defaultServer"
let TR_URL_CONFIG_PATH = "rpcPath"
let TR_URL_CONFIG_FREE = "showFreeSpace"
let TR_URL_CONFIG_REFRESH = "refreshTimeOut"
let TR_URL_CONFIG_REQUEST = "requestTimeOut"

@objcMembers

class ServerConfigDB: NSObject {
    
    private var configData: [RPCServerConfig] = []
 
    static let shared: ServerConfigDB = ServerConfigDB()
    
    let store = NSUbiquitousKeyValueStore.default
    
    let defaults = UserDefaults(suiteName: TR_URL_DEFAULTS)
    
    // closed init method
    private override init() {
        super.init()
        configData = []
    }
    
    
    var db: [RPCServerConfig] {
        set(newConfig) {
            configData = newConfig
        }
        get {
            return configData
        }
    }
    
    
    func load() {
        do {
            if let data = store.data(forKey: TR_URL_CONFIG_KEY) {
                let decoder = PropertyListDecoder()
                configData = try decoder.decode([RPCServerConfig].self, from: data)
            } else {
                guard let data = defaults?.data(forKey: TR_URL_CONFIG_KEY) else {return}
                let decoder = PropertyListDecoder()
                configData = try decoder.decode([RPCServerConfig].self, from: data)
            }
        } catch {
            os_log("%@",error.localizedDescription)
        }
    }
    
    
    var defaultConfig: RPCServerConfig? {
        return configData.first(where: { $0.defaultServer })
    }
    
    
    func save() {
        let encoder = PropertyListEncoder()
        //encoder.outputFormat = .binary
        let data = try! encoder.encode(configData)
        store.set(data, forKey: TR_URL_CONFIG_KEY)
        defaults?.set(data, forKey: TR_URL_CONFIG_KEY)
        store.synchronize()
        defaults?.synchronize()
    }
}
