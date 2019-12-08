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


public struct RPCServerConfig: Codable {
    
    static var config: RPCServerConfig = RPCServerConfig()
    
    var name: String = "" /* common server name */
    var host: String = "" /* ip address of domain name of server */
    var port: Int = 0 /* RPC port to connect to (default 8090) */
    var rpcPath: String = "" /* rpc path (default /transmission/remote/rpc */
    var userName: String = "" /* http basic auth user name */
    var userPassword: String = "" /* http basic auth password */
    var useSSL: Bool = false /* use https */
    var defaultServer: Bool = false
    var requireAuth: Bool = false
    var showFreeSpace: Bool = false /* update free space on server info */
    var refreshTimeout: TimeInterval = 0 /* refresh time in seconds */
    var requestTimeout: TimeInterval = 0 /* request timeout to server in seconds */

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
    
    init() {
        name = RPC_DEFAULT_NAME
        host = RPC_DEFAULT_HOST
        refreshTimeout = RPC_DEFAULT_REFRESH_TIME
        requestTimeout = RPC_DEFAULT_REQUEST_TIMEOUT
        port = RPC_DEFAULT_PORT
        rpcPath = RPC_DEFAULT_PATH
        useSSL = RPC_DEFAULT_USE_SSL
        showFreeSpace = RPC_DEFAULT_SHOWFREESPACE
    }
    
    var configDescription: String? {
        return String(format: "RPCServerConfig[%@://%@:%i%@, refresh:%is, request timeout: %is]", useSSL ? "https" : "http", host, port, rpcPath, refreshTimeout , requestTimeout )
    }
    
    
    var urlString: String {
        var rpcPath: String = ""
        if !(rpcPath.hasPrefix("/")) {
            rpcPath = "/\(self.rpcPath)"
        }
        else {
            rpcPath = self.rpcPath
        }
        return String(format: "%@://%@:%i%@", useSSL ? "https" : "http", host, port, rpcPath)
    }
    
    
    var configURL: URL? {
        let stringURL = "\(useSSL ? "https" : "http")://\(userName)\(!userPassword.isEmpty ? ":" : "")\(userPassword)@\(host)\(port != 0 ? ":" : "")\(port )\(rpcPath)"
        guard let theURL = URL(string: stringURL) else {return nil}
        return theURL
    }
}


extension RPCServerConfig: Equatable {
    
    public static func == (lhs: RPCServerConfig, rhs: RPCServerConfig) -> Bool {
        return lhs.name == rhs.name
    }
    
    public static func != (lhs: RPCServerConfig, rhs: RPCServerConfig) -> Bool {
        return lhs.name != rhs.name
    }
    
}
