//
//  SessionStatsController.swift
//  Transmission Remote
//
//  Created by  on 10/25/19.
//

import UIKit
import TransmissionRPC

class SessionStatsController: CommonTableController {
    
    @IBOutlet weak var labelDownloadSpeed: UILabel!
    @IBOutlet weak var labelUploadSpeed: UILabel!
    @IBOutlet weak var labelActiveTorrents: UILabel!
    @IBOutlet weak var labelPausedTorrents: UILabel!
    @IBOutlet weak var labelTotalTorrents: UILabel!
    @IBOutlet weak var labelCurrentBytesDownloaded: UILabel!
    @IBOutlet weak var labelCurrentBytesUploaded: UILabel!
    @IBOutlet weak var labelCurrentAddedFiles: UILabel!
    @IBOutlet weak var labelCurrentActiveTime: UILabel!
    @IBOutlet weak var labelCurrentSessions: UILabel!
    @IBOutlet weak var labelCumulativeBytesDownloaded: UILabel!
    @IBOutlet weak var labelCumulativeBytesUploaded: UILabel!
    @IBOutlet weak var labelCumulativeAddedFiles: UILabel!
    @IBOutlet weak var labelCumulativeActiveTime: UILabel!
    @IBOutlet weak var labelCumulativeSessions: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let blurEffect = UIBlurEffect(style: .regular)
        let viewVisualEffect = UIVisualEffectView(effect: blurEffect)
        viewVisualEffect.frame = tableView.bounds
        viewVisualEffect.layer.masksToBounds = true
       tableView.backgroundView = viewVisualEffect
       tableView.addSubview(viewVisualEffect)
//        tableView.sendSubviewToBack(viewVisualEffect)
//        tableView.alpha = 0.7
    }
    
/*    override func viewWillAppear(_ animated: Bool) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if UIApplication.shared.windows[0].traitCollection.horizontalSizeClass == .compact {
                self.view.frame.size = UIApplication.shared.windows[0].bounds.size
                self.view.bounds.size = UIApplication.shared.windows[0].bounds.size
                self.view.setNeedsLayout()
            }
            else {
                self.view.frame.size = CGSize(width: 504, height: 800)
                self.view.bounds.size = CGSize(width: 504, height: 800)
                self.view.layoutSubviews()
            }
        }
    }
 */
    override func viewDidAppear(_ animated: Bool) {
        session.getSessionStats { (sessionStats, error) in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                }
                else {
                    guard let sessionStats = sessionStats else {return}
                    self.labelDownloadSpeed.text = formatByteRate(sessionStats.downloadSpeed)
                    self.labelUploadSpeed.text = formatByteRate(sessionStats.uploadSpeed)
                    self.labelActiveTorrents.text = String(sessionStats.activeTorrentCount)
                    self.labelPausedTorrents.text = String(sessionStats.pausedTorrentCount)
                    self.labelTotalTorrents.text = String(sessionStats.torrentCount)
                    self.labelCurrentBytesDownloaded.text = formatByteCount(sessionStats.currentdownloadedBytes)
                    self.labelCurrentBytesUploaded.text = formatByteCount(sessionStats.currentUploadedBytes)
                    self.labelCurrentAddedFiles.text = String(sessionStats.currentFilesAdded)
                    self.labelCurrentActiveTime.text = formatHoursMinutes(sessionStats.currentSecondsActive)
                    self.labelCurrentSessions.text = String(sessionStats.currentsessionCount)
                    self.labelCumulativeBytesDownloaded.text = formatByteCount(sessionStats.cumulativedownloadedBytes)
                    self.labelCumulativeBytesUploaded.text = formatByteCount(sessionStats.cumulativeUploadedBytes)
                    self.labelCumulativeAddedFiles.text = String(sessionStats.cumulativeFilesAdded)
                    self.labelCumulativeActiveTime.text = formatHoursMinutes(sessionStats.cumulativeSecondsActive)
                    self.labelCumulativeSessions.text = String(sessionStats.cumulativesessionCount)
                    
                }
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
}
