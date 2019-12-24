//
//  ResfreshTimerProtocol.swift
//  Transmission Remote
//
//  Created by  on 10/16/19.
//

import Foundation
import TransmissionRPC

var globalRefreshTimer: Timer = Timer()

@objc protocol RefreshTimer: NSObjectProtocol {
    func updateData(_ sender: Any?)
}


extension RefreshTimer {
    
    func startRefresh() {
        updateData(nil)
        globalRefreshTimer = Timer.scheduledTimer(timeInterval: RPCServerConfig.sharedConfig!.refreshTimeout, target: self, selector: #selector(updateData(_:)), userInfo: nil, repeats: true)
    }
    
    func stopRefresh() {
        if globalRefreshTimer.isValid {
            globalRefreshTimer.invalidate()
        }
        RPCSession.shared?.stopRequests()
    }
}

extension Notification.Name {
    /// Notification for when download progress has changed.
    static let EnableTimers = Notification.Name(rawValue: "EnableTimersNotification")
}
