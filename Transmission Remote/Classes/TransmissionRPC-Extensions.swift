//
//  TransmissionRPC-Extensions.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

import UIKit
import TransmissionRPC

extension Torrent {
    
    var iconType: IconCloudType {
        if isError {
            return IconCloudType.Error
        }
        else if isDownloading {
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

    var detailStatus: String! {
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
    
    var peersDetail: String! {
        if isError {
            return NSLocalizedString("Error: \(errorString ?? "")", comment: "")
        }
        else if !(isStopped || isFinished || isChecking || isWaiting) {
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
    
    var statusColor: UIColor {
        if isError {
            return UIColor.colorError!
        }
        else if isDownloading {
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

}
