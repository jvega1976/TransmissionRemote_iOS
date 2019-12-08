//
//  TorrentListCell.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

import UIKit
import TransmissionRPC

class TorrentListCell: UITableViewCell {

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
    @IBOutlet weak var iconRateLimit: UIImageView!
    @IBOutlet weak var iconRatioLimit: UIImageView!
    @IBOutlet weak var iconIdleLimit: UIImageView!
    @IBOutlet weak var iconPriority: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func update(withTRInfo torrent:Torrent) {
        torrentId = torrent.trId
        name.text = torrent.name
        
        if(torrent.isChecking) {
            progressBar.progress = Float(torrent.recheckProgress)
        }
        else {
            progressBar.progress = Float(torrent.percentsDone)
        }
        progressBar.progressColor = torrent.statusColor
        statusIcon.tintColor(torrent.statusColor)
        statusIcon.iconType(torrent.iconType)
        //        progressBar.tintColor = torrent.statusColor
        size.text = torrent.totalSizeString
        peersInfo.text = torrent.peersDetail
        detailStatus.text = torrent.detailStatus
        progressPercents.text = torrent.percentsDoneString
        
        if statusIcon.iconType == IconCloudType.Download && torrent.downloadRate > 0 {
            statusIcon.playDownloadAnimation()
        }
        else {
            statusIcon.stopDownloadAnimation()
        }
        if statusIcon.iconType == IconCloudType.Upload && torrent.uploadRate > 0 {
            statusIcon.playUploadAnimation()
        }
        else {
            statusIcon.stopUploadAnimation()
        }
        if statusIcon.iconType == IconCloudType.Wait {
            statusIcon.playWaitAnimation()
        }
        else {
            statusIcon.stopWaitAnimation()
        }
        if statusIcon.iconType == IconCloudType.Verify {
            statusIcon.playCheckAnimation()
        }
        else {
            statusIcon.stopCheckAnimation()
        }
        
        if torrent.isDownloading || torrent.isWaiting || torrent.isSeeding {
            iconPlayPause.setImage(UIImage(named: "iconStop36x36"), for: UIControl.State.normal)
        }
        else if torrent.isFinished || torrent.isStopped {
            iconPlayPause.setImage(UIImage(named: "iconPlay36x36"), for: UIControl.State.normal)
        }
        
        iconRateLimit.isHidden = !(torrent.downloadLimitEnabled || torrent.uploadLimitEnabled)
        iconRatioLimit.isHidden = !(torrent.seedRatioMode != 0)
        iconIdleLimit.isHidden = !(torrent.seedIdleMode != 0)
        iconPriority.isHidden = torrent.bandwidthPriority == 0
        
        switch torrent.bandwidthPriority {
            case 1:
                iconPriority.tintColor = .systemPink
            case -1:
                iconPriority.tintColor = .systemYellow
            default:
                break
        }
        
        iconRateLimit.image = iconRateLimit.image!.withRenderingMode(.alwaysTemplate)
        iconIdleLimit.image = iconIdleLimit.image!.withRenderingMode(.alwaysTemplate)
        iconRatioLimit.image = iconRatioLimit.image!.withRenderingMode(.alwaysTemplate)
        
    }

}
