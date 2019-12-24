//
//  TransmissionRPC-Extensions.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#else
import Cocoa
#endif

import TransmissionRPC
import Categorization

extension Torrent {
    
    var ratioLimitEnabled: Bool {
        return seedRatioMode == 1
    }
    
    //private static var iconCloudContext = 0
    
    /*var iconCloud: IconCloud {
        get {
            if let iconCloud = objc_getAssociatedObject(self, &Torrent.iconCloudContext) as? IconCloud {
                if iconCloud.iconType != self.iconType {
                    iconCloud.iconType = self.iconType
                    iconCloud.contentColor = self.statusColor
                    iconCloud.needsDisplay = true
                }
                return iconCloud
                
            } else {
                let iconCloud = IconCloud()
                iconCloud.iconType = self.iconType
                iconCloud.contentColor = self.statusColor
                iconCloud.needsDisplay = true
                objc_setAssociatedObject(self, &Torrent.iconCloudContext, iconCloud, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return iconCloud
            }
        }
        set(newIcon) {
            objc_setAssociatedObject(self, &Torrent.iconCloudContext, newIcon, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }*/
    
    @objc dynamic var iconType: IconCloudType {
        if isDownloading {
            return IconCloudType.Download
        }
        else if isSeeding {
            return IconCloudType.Upload
        }
        else if isStopped {
            return IconCloudType.Pause
        }
        else if isWaiting {
            return IconCloudType.Wait
        }
        else if isChecking {
            return IconCloudType.Verify
        }
        else if isFinished {
            return IconCloudType.Completed
        }
        return IconCloudType.All
    }

    @objc dynamic var detailStatus: String! {
        if isError {
            return NSLocalizedString("Error: \(errorString ?? "")", comment: "")
        } else if isSeeding {
            return String(format: NSLocalizedString("%@", comment: ""),uploadRateString)
        } else if isDownloading {
            return String(format: NSLocalizedString("%@ %@, ETA: %@", comment: ""), downloadRateString, uploadRateString, etaTimeString)
        } else if isStopped {
            return NSLocalizedString("Paused", comment: "TorrentListController torrent info")
        } else if isChecking {
            return NSLocalizedString("Verifying data ...", comment: "")
        } else if isFinished {
            return "Completed"
        } else if isWaiting {
            return statusString
        }
        return "Unknown"
    }
    
    class func keyPathsForValuesAffectingDetailStatus() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["errorString","uploadRate","downloadRate","eta","status"])
    }
    
    @objc dynamic var peersDetail: String! {
        if !(isStopped || isFinished || isChecking || isWaiting) {
            return String(format: NSLocalizedString("↓DL %ld and ↑UL %ld from %ld Peers", comment: ""), peersSendingToUs, peersGettingFromUs, peersConnected)
        } else if isStopped {
            return NSLocalizedString("Paused", comment: "TorrentListController torrent info")
        } else if isFinished {
            return "Completed"
        } else if isChecking {
            return NSLocalizedString("Verifying data ...", comment: "")
        } else if isWaiting {
            return statusString
        }
        return "Unknown"
    }
    
    class func keyPathsForValuesAffectingPeersDetail() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["peersSendingToUs","peersGettingFromUs","peersConnected","status"])
    }
   
    #if os(iOS) || targetEnvironment(macCatalyst)
    var statusColor: UIColor {
       if isDownloading {
            return UIColor.colorDownload!
        }
        else if isSeeding {
            return UIColor.colorUpload!
        }
        else if isStopped {
            return UIColor.colorPaused!
        }
        else if isWaiting {
            return UIColor.colorWait!
        }
        else if isChecking {
            return UIColor.colorVerify!
        }
        else if isFinished {
            return UIColor.colorCompleted!
        }
        return UIColor.systemFill
    }
    #else
    var statusColor: NSColor {
        if isDownloading {
            return NSColor.colorDownload
        }
        else if isSeeding {
            return NSColor.colorUpload!
        }
        else if isStopped {
            return NSColor.colorPaused
        }
        else if isWaiting {
            return NSColor.colorWait!
        }
        else if isChecking {
            return NSColor.colorVerify!
        }
        else if isFinished {
            return NSColor.colorCompleted
        }
        return NSColor.controlColor
    }
    #endif

}

extension Torrent: CategoryElement {
    
    @objc open func update(with item: AnyObject) {
        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(Torrent.self, &count) else {
            return
        }
        for index in 0..<count {
            let property = String(cString: property_getName(properties[Int(index)]))
            guard let attributeChar = property_getAttributes(properties[Int(index)]) else { continue }
            if !(String(cString: attributeChar).split(separator: ",").contains("R")) {
                guard let value = item.value(forKey: property) else { continue }
                self.setValue(value,forKey: property)
            }
        }
    }
}



#if os(iOS) || targetEnvironment(macCatalyst)
@objc public extension FSItem {
    
    private static var isExpandedContext = 0
    
    @objc dynamic var isExpanded: Bool {
        get {
            guard let value =  objc_getAssociatedObject(self, &FSItem.isExpandedContext) as? Bool else { return false }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &FSItem.isExpandedContext, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

#else
@objc public extension FSItem {
    @objc dynamic var fileIcon: NSImage? {
        if self.isFolder {
            return NSImage(named: "NSTouchBarFolderTemplate")
        } else {
            return NSImage(named: "file")
        }
    }
    
    @objc dynamic var downloadProgressDouble: Double {
        return Double(self.downloadProgress * 100)
    }
    
    class func keyPathsForValuesAffectingDownloadProgressDouble() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["downloadProgress"])
    }
    
    @objc dynamic var detailInfo: String {
        return "\(formatByteCount(Int(Float(self.size) * self.downloadProgress))) of \(self.sizeString) (\(self.downloadProgressString))"
    }
    
    
    class func keyPathsForValuesAffectingzDetailInfo() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["size","downloadProgress","sizeString","downloadProgressString"])
    }
}
#endif
