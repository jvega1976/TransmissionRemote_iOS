//
//  TorrentInfoControler.swift
//  Transmission Remote
//
//  Created by  on 7/16/19.
//

import UIKit
import TransmissionRPC
import Categorization

class TorrentInfoController: CommonTableController {
   
    @IBOutlet weak var torrentNameLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var haveLabel: UILabel!
    @IBOutlet weak var downloadedLabel: UILabel!
    @IBOutlet weak var downloadFolder: UILabel!
    @IBOutlet weak var uploadedLabel: UILabel!
    @IBOutlet weak var ratioLabel: UILabel!
 //   @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentLabel: UITextView!
    
    @IBOutlet weak var dateAddedLabel: UILabel!
    @IBOutlet weak var dateCompletedLabel: UILabel!
    @IBOutlet weak var dateLastActivityLabel: UILabel!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var creatorLabel: UILabel!
    @IBOutlet weak var uploadingTimeLabel: UILabel!
    @IBOutlet weak var downloadingTimeLabel: UILabel!
    @IBOutlet weak var hashTextView: UITextView!
    @IBOutlet weak var stepperQueuePosition: UIStepper!
    @IBOutlet weak var textQueuePosition: UITextField!
    @IBOutlet weak var segmentBandwidthPriority: UISegmentedControl!
    @IBOutlet weak var switchUploadLimit: UISwitch!
    @IBOutlet weak var textUploadLimit: UITextField!
    @IBOutlet weak var switchDownloadLimit: UISwitch!
    @IBOutlet weak var textDownloadLimit: UITextField!
    @IBOutlet weak var switchRatioLimit: UISwitch!
    @IBOutlet weak var textSeedRatioLimit: UITextField!
    @IBOutlet weak var switchSeedIdleLimit: UISwitch!
    @IBOutlet weak var textSeedIdleLimit: UITextField!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var upDownSpeedLabel: UILabel!


    var enableControls = false
    var completionHandler: ((Error?)->Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        completionHandler = { error in
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = error!.localizedDescription
                }
            }
        }
        torrentNameLabel.text = torrent.name
        stateLabel.text = torrent.statusString
        downloadFolder.text = torrent.downloadDir
        progressLabel.text = torrent.isChecking ? torrent.recheckProgressString : torrent.percentsDoneString//
        haveLabel.text = torrent.haveValidString
        downloadedLabel.text = torrent.downloadedEverString
        uploadedLabel.text = torrent.uploadedEverString
        ratioLabel.text = String(format: "%02.2f", torrent!.uploadRatio)
        commentLabel.text = torrent.comment
        dateAddedLabel.text = torrent.dateAddedString
        dateCompletedLabel.text = torrent.dateDoneString
        dateLastActivityLabel.text = torrent.dateLastActivityString
        dateCreatedLabel.text = torrent.dateCreatedString
        creatorLabel.text = torrent.creator
        uploadingTimeLabel.text = torrent.seedingTimeString
        downloadingTimeLabel.text = torrent.downloadingTimeString
        hashTextView.text = torrent.hashString
        stepperQueuePosition.value = Double(torrent.queuePosition)
        textQueuePosition.text = String(format: "%ld", torrent.queuePosition)
        segmentBandwidthPriority.selectedSegmentIndex = torrent.bandwidthPriority + 1
        switchUploadLimit.isOn = torrent.uploadLimitEnabled
        textUploadLimit.text = String(format: "%ld", torrent.uploadLimit)
        switchDownloadLimit.isOn = torrent.downloadLimitEnabled
        textDownloadLimit.text = String(format: "%ld", torrent.downloadLimit)
        switchRatioLimit.isOn = torrent.seedRatioMode > 0
        textSeedRatioLimit.text = String(torrent.seedRatioLimit)
        switchSeedIdleLimit.isOn = torrent.seedIdleMode > 0
        textSeedIdleLimit.text =  String(torrent.seedIdleLimit)
        sizeLabel.text = formatByteCount(torrent!.totalSize)
        if torrent.isSeeding {
            upDownSpeedLabel.text = torrent.uploadRateString
        }
        else if torrent.isFinished || torrent.isStopped {
            upDownSpeedLabel.text = torrent.downloadRateString
        } else {
            upDownSpeedLabel.text = String(format: "%@ / %@", torrent.uploadRateString , torrent.downloadRateString )
        }
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(updateData), for: .valueChanged)
        (parent as! TorrentDetailsController).navigationItem.title = nil
        let pauseButton = UIBarButtonItem(image: UIImage(systemName: "pause.circle"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(pauseTorrent(_:)))
        let resumeButton = UIBarButtonItem(image: UIImage(systemName: "play.circle"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(resumeTorrent(_:)))
         let resumeNowButton = UIBarButtonItem(image: UIImage(systemName: "livephoto.play"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(resumeNowTorrent(_:)))
        let removeButton = UIBarButtonItem(image: UIImage(systemName: "trash.circle"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(removeTorrent(_:)))
        let updateButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise.circle"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(reannounceTorrent(_:)))
        let verifyButton = UIBarButtonItem(image: UIImage(systemName: "checkmark.circle"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(verifyTorrent(_:)))
        parent!.navigationItem.rightBarButtonItems = [resumeButton, resumeNowButton, pauseButton, removeButton,updateButton,verifyButton]
    }
    
    @objc override func updateData(_ sender: Any? = nil) {
        session.getInfo(forTorrents: [torrent.trId]) { (torrents, removed, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = error!.localizedDescription
                    return
                }
                self.updateTorrent(withInfo: torrents!.first!)
            }
        }
        
    }
    
    
    @IBAction @objc func updatePriority(_ sender: UISegmentedControl) {
        torrent.bandwidthPriority = sender.selectedSegmentIndex - 1
        session.setFields(torrent.jsonObject, forTorrents: [torrent!.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @IBAction @objc func updatePosition(_ sender: UIControl) {
        if sender is UIStepper {
            torrent.queuePosition = Int(stepperQueuePosition.value)
            textQueuePosition.text = String(format:"%l", stepperQueuePosition.value)
        } else if sender is UITextField {
            torrent.queuePosition = Int(textQueuePosition.text!)!
            stepperQueuePosition.value = Double(textQueuePosition.text!)!
        } else {
            return
        }
        session.setFields(torrent.jsonObject, forTorrents: [torrent!.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @IBAction @objc func updateDownloadLimit(_ sender: UIControl) {
        if let isDownloadEnabled = sender as? UISwitch {
            torrent.downloadLimitEnabled = isDownloadEnabled.isOn
        } else if let downloadLimit = sender as? UITextField {
            torrent.downloadLimit = Int(downloadLimit.text!)!
        }
        session.setFields(torrent.jsonObject, forTorrents: [torrent!.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @IBAction @objc func updateUploadLimit(_ sender: UIControl) {
        if sender is UISwitch {
            torrent.uploadLimitEnabled = switchUploadLimit.isOn
        } else if let uploadLimit = sender as? UITextField {
            torrent.uploadLimit = Int(uploadLimit.text!)!
        }
        session.setFields(torrent.jsonObject, forTorrents: [torrent!.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @IBAction @objc func updateRatioLimit(_ sender: UIControl) {
        if let isRatioLimitEnabled = sender as? UISwitch {
            torrent.seedRatioMode = isRatioLimitEnabled.isOn ? 1 : 0
        } else if let ratioLimit = sender as? UITextField {
            torrent.seedRatioLimit = Double(ratioLimit.text!)!
        }
        session.setFields(torrent.jsonObject, forTorrents: [torrent!.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @IBAction @objc func updateIdleLimit(_ sender: UIControl) {
        if let isIdleLimited = sender as? UISwitch {
            torrent.seedIdleMode = isIdleLimited.isOn ? 1 : 0
        } else if let idleLimit = sender as? UITextField {
            torrent.seedIdleLimit = Int(idleLimit.text!)!
        }
        session.setFields(torrent.jsonObject, forTorrents: [torrent!.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @objc func pauseTorrent(_ sender: UIBarButtonItem) {
        infoMessage = "Pausing Torrent..."
        session.stop(torrents: [torrent.trId], withPriority: .veryHigh, completionHandler: completionHandler)
        
    }
    
    
    @objc func resumeTorrent(_ sender: UIBarButtonItem) {
         infoMessage = "Resuming Torrent..."
        session.start(torrents: [torrent.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @objc func resumeNowTorrent(_ sender: UIBarButtonItem) {
         infoMessage = "Resuming Torrent..."
        session.startNow(torrents: [torrent.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @objc func reannounceTorrent(_ sender: UIBarButtonItem) {
        infoMessage = "Reannouncing Torrent..."
        session.reannounce(torrents: [torrent.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @objc func verifyTorrent(_ sender: UIBarButtonItem) {
        session.verify(torrents: [torrent.trId], withPriority: .veryHigh, completionHandler: completionHandler)
    }
    
    
    @objc func removeTorrent(_ sender: UIBarButtonItem) {
        let removeDataAlert = UIAlertController(title: "Delete Torrent", message: "Do you want to delete the torrent's data files?", preferredStyle: .alert)
        removeDataAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
            self.session.remove(torrents: [self.torrent.trId], deletingLocalData: true, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        self.errorMessage = error!.localizedDescription
                    }
                    self.navigationController!.popToViewController((self.parent as! TorrentDetailsController).torrentListController, animated: true)
                }
            })
        }))
        removeDataAlert.addAction(UIAlertAction(title: "No", style: .default, handler: {_ in
            self.session.remove(torrents: [self.torrent.trId], deletingLocalData: false, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        self.errorMessage = error!.localizedDescription
                    }
                    self.navigationController!.popToViewController((self.parent as! TorrentDetailsController).torrentListController, animated: true)
                }
            })
        }))
        removeDataAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        self.present(removeDataAlert, animated: true, completion: nil)
    }
    
    // MARK: - RPCConnector Protocol
    
    func updateTorrent(withInfo torrent: Torrent) {
            self.torrent = torrent
            self.torrentNameLabel.text = self.torrent.name
        self.downloadFolder.text = self.torrent.downloadDir
            self.stateLabel.text = self.torrent.statusString
            self.progressLabel.text = self.torrent.isChecking ? self.torrent.recheckProgressString : self.torrent.percentsDoneString
            self.progressLabel.setNeedsDisplay()
            self.haveLabel.text = self.torrent.haveValidString
            self.downloadedLabel.text = self.torrent.downloadedEverString
            self.uploadedLabel.text = self.torrent.uploadedEverString
            self.ratioLabel.text = String(format: "%02.2f", self.torrent!.uploadRatio)
            self.commentLabel.text = self.torrent.comment
            self.dateAddedLabel.text = self.torrent.dateAddedString
            self.dateCompletedLabel.text = self.torrent.dateDoneString
            self.dateLastActivityLabel.text = self.torrent.dateLastActivityString
            self.dateCreatedLabel.text = self.torrent.dateCreatedString
            self.creatorLabel.text = self.torrent.creator
            self.uploadingTimeLabel.text = self.torrent.seedingTimeString
            self.downloadingTimeLabel.text = self.torrent.downloadingTimeString
            self.hashTextView.text = self.torrent.hashString
            self.stepperQueuePosition.value = Double(self.torrent.queuePosition)
            self.textQueuePosition.text = String(format: "%ld", self.torrent.queuePosition)
            self.segmentBandwidthPriority.selectedSegmentIndex = self.torrent.bandwidthPriority + 1
            self.switchUploadLimit.isOn = self.torrent.uploadLimitEnabled
            if !self.textUploadLimit.isEditing {
                self.textUploadLimit.text = String(format: "%ld", self.torrent.uploadLimit)
            }
            self.switchDownloadLimit.isOn = self.torrent.downloadLimitEnabled
            if !self.textDownloadLimit.isEditing {
                self.textDownloadLimit.text = String(format: "%ld", self.torrent.downloadLimit)
            }
            self.switchRatioLimit.isOn = self.torrent.seedRatioMode > 0
            if !self.textSeedRatioLimit.isEditing {
                self.textSeedRatioLimit.text = String(self.torrent.seedRatioLimit)
            }
            self.switchSeedIdleLimit.isOn = self.torrent.seedIdleMode > 0
            if !self.textSeedIdleLimit.isEditing {
                self.textSeedIdleLimit.text = String(self.torrent.seedIdleLimit)
            }
            self.sizeLabel.text = formatByteCount(self.torrent!.totalSize)
            if self.torrent.isSeeding {
                self.upDownSpeedLabel.text = self.torrent.uploadRateString
            }
            else if self.torrent.isFinished || self.torrent.isStopped {
                self.upDownSpeedLabel.text = self.torrent.downloadRateString
            } else {
                self.upDownSpeedLabel.text = String(format: "%@ / %@", self.torrent.uploadRateString, self.torrent.downloadRateString)
            }
            TorrentCategorization.shared.updateItem(withInfo: self.torrent)
    }
    
}
