//
//  TorrentCellView.swift
//  Transmission Remote
//
//  Created by  on 12/14/19.
//

import Cocoa
import TransmissionRPC
import Categorization

class TorrentCellView: NSTableCellView, TableViewDataCell  {

    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var detailStatusLabel: NSTextField!
    @IBOutlet weak var peersDetailsLabel: NSTextField!
    @IBOutlet weak var sizeDetailsLabel: NSTextField!
    
    @IBOutlet weak var progressBarView: ProgressBar!
    @IBOutlet weak var progressLabel: NSTextField!
    
    @IBOutlet weak var disclouserButton: NSButton!
//    @IBOutlet weak var disclouserButton: NSBox!
    
    @IBOutlet weak var iconCloud: IconCloud!
    @IBOutlet weak var startStopButton: NSButton!
    
    @IBOutlet weak var uploadLimitImage: NSImageView!
    @IBOutlet weak var downloadLimitImage: NSImageView!
    @IBOutlet weak var ratioImage: NSImageView!
    @IBOutlet weak var priorityImage: NSImageView!
    
    @IBOutlet weak var errorImage: NSImageView!
    
    
    @objc dynamic public var isSelected: Bool = false {
        didSet {
            disclouserButton.isHidden = !isSelected
        }
    }
    
    
    public func update(withItem item: Any) {
        guard let torrent = item as? Torrent else { return }
        self.objectValue = torrent
    
        name.stringValue = torrent.name
        //name.dataObject = torrent

        
        //progressBar.doubleValue = torrent.percentsDone * 100
        detailStatusLabel.stringValue = torrent.detailStatus
        peersDetailsLabel.stringValue = torrent.peersDetail
        sizeDetailsLabel.stringValue = torrent.totalSizeString
        //progressBar.controlTint
        progressLabel.stringValue = torrent.percentsDoneString
        progressBarView.progressColor = torrent.statusColor
        progressBarView.progress = Float(torrent.percentsDone)
        //self.iconCloud = torrent.iconCloud
        if iconCloud.iconType != torrent.iconType {
            iconCloud.iconType = torrent.iconType
            iconCloud.contentColor = torrent.statusColor
        }
        startStopButton.isEnabled = true
        startStopButton.dataObject = torrent.trId
        if torrent.status == .stopped {
            startStopButton.state = .off
            startStopButton.action = #selector(MainViewController.startTorrent(_:))
        } else {
            startStopButton.state = .on
            startStopButton.action = #selector(MainViewController.pauseTorrent(_:))
        }
        
        switch self.iconCloud.iconType {
            case .Download:
                if torrent.downloadRate > 0  && !(iconCloud.isDownloadAnimationInProgress){
                    iconCloud.playDownloadAnimation()
                } else if torrent.downloadRate == 0 && iconCloud.isDownloadAnimationInProgress {
                    iconCloud.stopDownloadAnimation()
                }
            case .Upload:
                if torrent.uploadRate > 0 && !(iconCloud.isUploadAnimationInProgress) {
                    iconCloud.playUploadAnimation()
                } else if torrent.uploadRate == 0 && iconCloud.isUploadAnimationInProgress {
                    iconCloud.stopUploadAnimation()
                }
            case .Wait:
                iconCloud.playWaitAnimation()
            case .Verify:
                iconCloud.playCheckAnimation()
            default:
                break
        }
        
        downloadLimitImage.isHidden = !torrent.downloadLimited
        uploadLimitImage.isHidden = !torrent.uploadLimited
        ratioImage.isHidden = !(torrent.ratioLimitEnabled || torrent.uploadRatio > torrent.seedRatioLimit)
        ratioImage.contentTintColor = (torrent.uploadRatio > torrent.seedRatioLimit) ? .systemGreen : .labelColor
        priorityImage.isHidden = !([-1,1].contains(torrent.bandwidthPriority))
        detailStatusLabel.textColor = torrent.isError ? .systemRed : .labelColor
        switch torrent.bandwidthPriority {
            case -1:
                priorityImage.contentTintColor = .colorVerify
            case 1:
                priorityImage.contentTintColor = .systemRed
            default:
                priorityImage.contentTintColor = .labelColor
        }
        errorImage.isHidden = !torrent.isError
    }
    
    
    
}
