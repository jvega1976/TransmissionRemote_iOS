//
//  TorrentListCell.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

import UIKit
import TransmissionRPC
import Categorization

@objcMembers public class TorrentListCell: UITableViewCell, TableViewDataCell {

    @IBOutlet weak var statusIcon: IconCloud!
//    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var iconPlayPause: UIButton!
    
    @IBOutlet weak var detailStatus: UILabel!
 
    @IBOutlet weak var size: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var progressPercents: UILabel!
    @IBOutlet weak var peersInfo: UILabel!
    @IBOutlet weak var progressBar: ProgressBar!
    
    var torrentId = 0
    @IBOutlet weak var iconUploadRateLimit: UIImageView!
    @IBOutlet weak var iconRatioLimit: UIImageView!
    @IBOutlet weak var iconDownloadRateLimit: UIImageView!
    @IBOutlet weak var iconPriority: UIImageView!
    @IBOutlet weak var iconError: UIImageView!
    
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc public func update(withItem item: Any) {
        guard let item = item as? Torrent else { return }
        torrentId = item.trId
        name.text = item.name
        
        if(item.isChecking) {
            progressBar.progress = Float(item.recheckProgress)
        }
        else {
            progressBar.progress = Float(item.percentsDone)
        }
        progressBar.progressColor = item.statusColor
        statusIcon.tintColor = item.statusColor
        statusIcon.iconType = item.iconType

        //        progressBar.tintColor = item.statusColor
        size.text = item.totalSizeString
        peersInfo.text = item.peersDetail
        detailStatus.text = item.detailStatus
        if item.isError {
            detailStatus.textColor = .systemRed
        } else {
            detailStatus.textColor = .label
        }
        progressPercents.text = item.percentsDoneString
        
        switch statusIcon.iconType {
            case .Download:
                if item.downloadRate > 0 && !statusIcon.isDownloadAnimationInProgress {
                    statusIcon.playDownloadAnimation()
                } else if item.downloadRate < 0 && statusIcon.isDownloadAnimationInProgress{
                    statusIcon.stopDownloadAnimation()
                }
            case .Upload:
                if item.uploadRate > 0  && !statusIcon.isUploadAnimationInProgress {
                    statusIcon.playUploadAnimation()
                } else if item.uploadRate <= 0  && statusIcon.isUploadAnimationInProgress {
                    statusIcon.stopUploadAnimation()
                }
            case .Verify:
                if !statusIcon.isCheckAnimationInProgress {
                    statusIcon.playCheckAnimation()
                }
            case .Wait:
                if !statusIcon.isWaitAnimationInProgres {
                    statusIcon.playWaitAnimation()
                }
            default:
                break
        }
        
        iconPlayPause.dataObject = item
        iconPlayPause.removeTarget(nil, action: #selector(TorrentTableController.pauseTorrents(_:)), for: .touchDown)
        iconPlayPause.removeTarget(nil, action: #selector(TorrentTableController.resumeTorrents(_:)), for: .touchDown)
        if item.isDownloading || item.isWaiting || item.isSeeding {
            iconPlayPause.setImage(UIImage(named: "Stop"), for: UIControl.State.normal)
            iconPlayPause.addTarget(nil, action: #selector(TorrentTableController.pauseTorrents(_:)), for: .touchDown)
        }
        else if item.isFinished || item.isStopped {
            iconPlayPause.setImage(UIImage(named: "Play"), for: UIControl.State.normal)
            iconPlayPause.addTarget(nil, action: #selector(TorrentTableController.resumeTorrents(_:)), for: .touchDown)
        }
        iconUploadRateLimit.isHidden = !(item.uploadLimited)
        iconDownloadRateLimit.isHidden = !(item.downloadLimited)
        iconRatioLimit.isHidden = !((item.seedRatioMode == 1) || (item.uploadRatio > 1.0))
        if item.uploadRatio > 1.0 {
            iconRatioLimit.tintColor = .systemGreen
        } else {
            iconRatioLimit.tintColor = .label
        }
        iconPriority.isHidden = item.bandwidthPriority == 0
        switch item.bandwidthPriority {
            case -1: iconPriority.tintColor = .systemYellow
            case 1: iconPriority.tintColor = .systemRed
            default: break
        }
        iconError.isHidden = !(item.isError)
        iconPlayPause.isEnabled = true
        setNeedsDisplay()
    }


}
