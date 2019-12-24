//  Converted to Swift 5 by Swiftify v5.0.37171 - https://objectivec2swift.com/
//
//  RPCServerConfig.swift
//  Transmission Remote
//  Holds transmission remote rpc settings
//
//  Created by  on 7/11/19.
//

import Foundation

let RPC_DEFAULT_PORT = 9091
let RPC_DEFAULT_PATH = "/transmission/rpc"
let RPC_DEFAULT_REFRESH_TIME = 5.0
let RPC_DEFAULT_REQUEST_TIMEOUT = 10.0
let RPC_DEFAULT_USE_SSL = false
let RPC_DEFAULT_NAME = "Enter Name"
let RPC_DEFAULT_HOST = "Enter Hostname"
let RPC_DEFAULT_SHOWFREESPACE = true

@objc(RPCServerConfig)

public class RPCServerConfig: NSObject, Codable {
    
    @objc dynamic static var sharedConfig: RPCServerConfig?
    
    @objc dynamic var name: String = "" /* common server name */
    @objc dynamic var host: String = "" /* ip address of domain name of server */
    @objc dynamic var port: Int = 0 /* RPC port to connect to (default 8090) */
    @objc dynamic var rpcPath: String = "" /* rpc path (default /transmission/remote/rpc */
    @objc dynamic var userName: String = "" /* http basic auth user name */
    @objc dynamic var userPassword: String = "" /* http basic auth password */
    @objc dynamic var useSSL: Bool = false /* use https */
    @objc dynamic var defaultServer: Bool = false
    @objc dynamic var requireAuth: Bool = false
    @objc dynamic var showFreeSpace: Bool = false /* update free space on server info */
    @objc dynamic var refreshTimeout: TimeInterval = 0 /* refresh time in seconds */
    @objc dynamic var requestTimeout: TimeInterval = 0 /* request timeout to server in seconds */

    private enum CodingKeys: String,CodingKey {
        case name
        case host
        case port
        case rpcPath
        case userName
        case userPassword
        case useSSL
        case defaultServer
        case requireAuth
        case showFreeSpace
        case refreshTimeout
        case requestTimeout
    }
    
    public override init() {
        super.init()
        self.name = RPC_DEFAULT_NAME
        self.host = RPC_DEFAULT_HOST
        self.refreshTimeout = RPC_DEFAULT_REFRESH_TIME
        self.requestTimeout = RPC_DEFAULT_REQUEST_TIMEOUT
        self.port = RPC_DEFAULT_PORT
        self.rpcPath = RPC_DEFAULT_PATH
        self.useSSL = RPC_DEFAULT_USE_SSL
        self.showFreeSpace = RPC_DEFAULT_SHOWFREESPACE
    }
    
    @objc dynamic public var configDescription: String? {
        return String(format: "RPCServerConfig[%@://%@:%i%@, refresh:%is, request timeout: %is]", useSSL ? "https" : "http", host, port, rpcPath, refreshTimeout , requestTimeout )
    }
    
    
    @objc dynamic public var urlString: String {
        var rpcPath: String = ""
        if !(rpcPath.hasPrefix("/")) {
            rpcPath = "/\(self.rpcPath)"
        }
        else {
            rpcPath = self.rpcPath
        }
        return String(format: "%@://%@:%i%@", useSSL ? "https" : "http", host, port, rpcPath)
    }
    
    
    @objc dynamic public var configURL: URL? {
        let stringURL = "\(useSSL ? "https" : "http")://\(userName)\(!userPassword.isEmpty ? ":" : "")\(userPassword)@\(host)\(port != 0 ? ":" : "")\(port )\(rpcPath)"
        guard let theURL = URL(string: stringURL) else {return nil}
        return theURL
    }
    
    @objc dynamic public var isSelected: Bool {
        return self.isEqual(RPCServerConfig.sharedConfig)
    }
}

// MARK:- Equatable Protocol

extension RPCServerConfig {
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let config = object as? RPCServerConfig else { return false }
        return self.name == config.name
    }
    
    public func isNotEqual(object: Any?) -> Bool {
        guard let config = object as? RPCServerConfig else { return true }
        return self.name != config.name
    }
    
    
    public static func == (lhs: RPCServerConfig, rhs: RPCServerConfig) -> Bool {
        return lhs.name == rhs.name
    }
    
    public static func != (lhs: RPCServerConfig, rhs: RPCServerConfig) -> Bool {
        return lhs.name != rhs.name
    }
    
}
