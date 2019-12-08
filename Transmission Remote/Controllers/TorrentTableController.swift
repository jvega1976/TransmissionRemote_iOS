//
//  TorrentTableController.swift
//  Transmission Remote
//
//  Created by  on 8/5/19.
//

import UIKit
import os
import TransmissionRPC
import Categorization

public enum SortField: String, CaseIterable {
    case name = "Name"
    case dateCompleted = "Date Completed"
    case dateAdded = "Date Added"
    case eta = "ETA"
    case percentage = "% Completed"
    case size = "Size"
    case seeds = "Seeds"
    case peers = "Peers"
    case downSpeed = "Download Speed"
    case upSpeed = "Upload Speed"
    case queuePos = "Queue Position"
    
    static var allValues: Array<String> {
        return SortField.allCases.map{ $0.rawValue }
    }
}

public enum SortDirection {
    case asc
    case desc
}

class TorrentTableController: CommonTableController,
    UISearchBarDelegate,
    UITableViewDropDelegate,
    UITableViewDragDelegate
{
    
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarEdit: UIToolbar!
    
    @IBOutlet weak var sectionHeaderView: UIView!
    @IBOutlet weak var torrentsCount: UILabel!
    
    @IBOutlet weak var uploadSpeed: UILabel!
    @IBOutlet weak var downloadSpeed: UILabel!
    @IBOutlet weak var downloadSpeedIcon: IconHalfCloud!
    @IBOutlet weak var uploadSpeedIcon: IconHalfCloud!
    
    @IBOutlet weak var freeSpaceIcon: UIImageView!
    @IBOutlet weak var freeSpaceLabel: UILabel!
    
    
    private weak var errorLabel: UILabel?
    private weak var infoLabel: UILabel?
    
    var categorization: TorrentCategorization!
    var category: TorrentCategory!
    var categoryIndex: Int! = -1
    var sortedBy: SortField! = .queuePos
    var sortDirection: SortDirection! = .desc
    var torrents: Array<Torrent>! = []
    var sessionConfig: SessionConfig!
    
    private var lastTimeChecked: TimeInterval!
    
    private var firstTime: Bool = true
    
    let defaults = UserDefaults.standard
    
    func fillNavigationBar() {
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = false
        
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        torrentsCount.text = nil
        categorization = TorrentCategorization.shared
        
        if categoryIndex == -1 {
            categoryIndex = TR_CAT_IDX_ALL
        }
        fillNavigationBar()
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(updateData(_:)), for: .valueChanged)
        sectionHeaderView.frame.size.width = self.view.frame.size.width
        sectionHeaderView.frame.size.height = 100
        tableView.sectionHeaderHeight = sectionHeaderView.bounds.height
        downloadSpeedIcon.iconType = IconHalfCloudType.download
        uploadSpeedIcon.iconType = IconHalfCloudType.upload
        self.tableView.dragDelegate = self
        self.tableView.dropDelegate = self
        self.view.isUserInteractionEnabled = true
        self.tableView.isUserInteractionEnabled = true
        self.tableView.dragInteractionEnabled = true
        
        freeSpaceIcon.isHidden = !RPCServerConfig.config.showFreeSpace
        freeSpaceLabel.isHidden = !RPCServerConfig.config.showFreeSpace
        tableView.setNeedsLayout()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeIconSpeedColor(_:)),
                                               name: .ChangeIconSpeedColor, object: nil)
    
    }
    
    
    override public func viewDidAppear(_ animated: Bool) {
        firstTime = true
        super.viewDidAppear(animated)
        lastTimeChecked = defaults.double(forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME)
        if lastTimeChecked == 0 {
            lastTimeChecked = Date().timeIntervalSince1970 - 180
        }
    }
    
    @objc override func startTimer(_ notification: Notification? = nil) {
        if notification != nil {
            try? RPCSession.shared?.restart()
        }
        session = RPCSession.shared
        firstTime = true
        startRefresh() //Method inherited from RefreshTimer Protocol
    }
    
    
    @objc override func updateData(_ sender: Any? = nil) {
        if sender is UIRefreshControl {
            firstTime = true
            if !globalRefreshTimer.isValid {
                try? RPCSession.shared?.restart()
                startRefresh()
                return
            }
        }
        
        if firstTime {
            session.getInfo(forTorrents: nil, withPriority: .veryHigh) { (torrents, removed, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        self.firstTime = true
                        self.updateData()
                        return
                    }
                    guard let torrents = torrents else {return}
                    
                    self.tableView.refreshControl!.endRefreshing()
                    // if All Torrents are received, just assign the array as categorization items
                    self.categorization.items = torrents
                    self.torrents = self.categorization.itemsforCategory(atPosition: self.categoryIndex)
                    if !self.tableView.isEditing {
                        self.tableView.reloadData()
                        self.torrentsCount.text = String(self.torrents.count)
                    }
                }
            }
            session.getSessionConfig(withPriority: .veryHigh) { (sessionConfig, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        return
                    }
                    guard let sessionConfig = sessionConfig else {return}
                    self.sessionConfig = sessionConfig
                    if sessionConfig.downLimitEnabled {
                        self.downloadSpeedIcon.tintColor = .red
                        self.downloadSpeed.textColor = .red
                    }
                    else if sessionConfig.upLimitEnabled {
                        self.uploadSpeedIcon.tintColor = .red
                        self.uploadSpeed.textColor = .red
                    }
                    if RPCServerConfig.config.showFreeSpace {
                        self.session.getFreeSpace(availableIn: sessionConfig.downloadDir) { (freeSpace, error) in
                            DispatchQueue.main.async {
                                if error != nil {
                                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                                } else {
                                    guard let freeSpace = freeSpace else { return }
                                    self.freeSpaceLabel.text = formatByteCount(freeSpace)
                                }
                            }
                        }
                    }
                }
            }
            firstTime = false
        } else {
            session.getInfo(forTorrents: RecentlyActive) { (torrents, removed, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        return
                    }
                    self.tableView.refreshControl!.beginRefreshing()
                    guard let torrents = torrents else {return}
                    
                    
                    // if All Torrents are received, just assign the array as categorization items
                    for torrent in torrents {
                        if let index = self.categorization.items.firstIndex(of: torrent) {
                            self.categorization.items[index] = torrent
                        } else {
                            self.categorization.items.insert(torrent, at: 0)
                        }
                    }
                    
                    if removed != nil {
                        for trId in removed! {
                            self.categorization.items.removeAll(where: {$0.trId == trId})
                        }
                    }
                    
                    self.torrents = self.categorization.itemsforCategory(atPosition: self.categoryIndex)
                    if !self.tableView.isEditing {
                        self.tableView.reloadData()
                        self.torrentsCount.text = String(self.torrents.count)
                    }
                    self.errorMessage = nil
                    self.tableView.refreshControl!.endRefreshing()
                }
            }
        }
        session.getSessionStats { (sessionStats, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = error?.localizedDescription
                    return
                }
                guard let stats = sessionStats else {return}
                self.downloadSpeed.text = formatByteRate(stats.downloadSpeed)
                if stats.downloadSpeed > 0 {
                    self.downloadSpeedIcon.playDownloadAnimation()
                }
                else {
                    self.downloadSpeedIcon.stopDownloadAnimation()
                }
                self.uploadSpeed.text = formatByteRate(stats.uploadSpeed)
                if stats.uploadSpeed > 0 {
                    self.uploadSpeedIcon.playUploadAnimation()
                }
                else {
                    self.uploadSpeedIcon.stopUploadAnimation()
                }
            }
        }
        showFinishedTorrents()
    }
    
    @objc func changeIconSpeedColor(_ notification: Notification) {
        if notification.userInfo!["isOn"] as? Bool ?? false {
            if notification.userInfo!["SpeedType"] as? String == "Upload" {
                self.uploadSpeedIcon.tintColor = .red
                self.uploadSpeed.textColor = .red
            }
            else if notification.userInfo!["SpeedType"] as? String == "Download" {
                self.downloadSpeedIcon.tintColor = .red
                self.downloadSpeed.textColor = .red
            }
        } else {
            if notification.userInfo!["SpeedType"] as? String == "Upload" {
                self.uploadSpeedIcon.tintColor = .secondaryLabel
                self.uploadSpeed.textColor = .secondaryLabel
            }
            else if notification.userInfo!["SpeedType"] as? String == "Download" {
                self.downloadSpeedIcon.tintColor = .secondaryLabel
                self.downloadSpeed.textColor = .secondaryLabel
            }
        }
    }
    
    // MARK: - Interface Actions
    
    func saveLastTimeChecked() {
        
        self.lastTimeChecked = Date().timeIntervalSince1970
        defaults.set(lastTimeChecked, forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME)
        defaults.synchronize()
    }
    
    
    
    @IBAction @objc func startAllTorrents(_ sender: UIBarButtonItem) {
        infoMessage = "Starting All Torrents..."
        session.start(torrents: nil, withPriority: .high) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
                else {
                    self.updateData()
                    displayInfoMessage("All Torrents successfully started", using: self.parent)
                }
            }
        }
    }
    
    
    @IBAction @objc func stopAllTorrentsAction(_ sender: UIBarButtonItem) {
        infoMessage = "Stopping All Torrents..."
        session.stop(torrents: nil, withPriority: .high) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
                else {
                    self.updateData()
                    displayInfoMessage("All Torrents successfully stopped", using: self.parent)
                }
            }
        }
    }
    
    
    @IBAction func startStopTorrentAction(_ sender: UIButton) {
        let point = sender.convert(sender.bounds.origin, to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else {return}
        let torrent = torrents[indexPath.row]
        if torrent.isDownloading || torrent.isSeeding || torrent.isWaiting {
            session.stop(torrents: [torrent.trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        self.torrents[indexPath.row].status = .stopped
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        displayInfoMessage("Torrent successfully stopped", using: self.parent)
                    }
                }
            }
        }
        else {
            session.start(torrents: [torrent.trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        displayInfoMessage("Torrent successfully started", using: self.parent)
                        self.session.getInfo(forTorrents: [torrent.trId], withPriority: .veryHigh) { (torrents, remove, error) in
                            DispatchQueue.main.async {
                                if error != nil {
                                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                                }
                                else  {
                                    self.torrents[indexPath.row] = torrents!.first!
                                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    @IBAction func longPress(_ sender: UIGestureRecognizer) {
        //        refreshTimer?.invalidate()
        let point = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
            let cell = tableView.cellForRow(at: indexPath) as? TorrentListCell else { return }
        let trId = torrents[indexPath.row].trId
        
        let alertActionStartNow = UIAlertAction(title: "Start Now", style: .default) { _ in
            
            self.session.startNow(torrents: [trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        displayInfoMessage("Torrent started successfully", using: self.parent)
                        self.session.getInfo(forTorrents: [trId], withPriority: .veryHigh) { (torrents, remove, error) in
                             DispatchQueue.main.async {
                                if error != nil {
                                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                                }
                                else {
                                    self.torrents[indexPath.row] = torrents!.first!
                                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let alertActionReannounce = UIAlertAction(title: "Reannounce", style: .default) { _ in
            self.session.reannounce(torrents: [trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        displayInfoMessage("Torrent reannounced successfully", using: self.parent)
                    }
                }
            }
        }
        
        let alertActionVerify = UIAlertAction(title: "Verify", style: .default) { _ in
            self.session.verify(torrents: [trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        self.session.getInfo(forTorrents: [trId], withPriority: .veryHigh) { (torrents, remove, error) in
                            DispatchQueue.main.async {
                                if error != nil {
                                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                                }
                                else  {
                                    self.torrents[indexPath.row] = torrents!.first!
                                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let alertActionRemove = UIAlertAction(title: "Remove", style: .default) { _ in
            let removeDataAlert = UIAlertController(title: "Delete Torrents", message: "Do you want to delete the torrent's data files?", preferredStyle: .alert)
            removeDataAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                self.session.remove(torrents: [trId], deletingLocalData: true, withPriority: .veryHigh) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            displayErrorMessage(error!.localizedDescription, using: self.parent)
                            
                        }
                        else {
                            self.torrents.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with: .automatic)
                            displayInfoMessage("Torrents sucessfully deleted", using: self.parent)
                        }
                    }
                }
            }))
            removeDataAlert.addAction(UIAlertAction(title: "No", style: .default, handler: {_ in
                self.session.remove(torrents: [trId], deletingLocalData: false, withPriority: .veryHigh) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            displayErrorMessage(error!.localizedDescription, using: self.parent)
                        }
                        else {
                            self.torrents.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with: .automatic)
                            displayInfoMessage("Torrents sucessfully deleted", using: self.parent)
                        }
                    }
                }
            }))
            removeDataAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(removeDataAlert, animated: true, completion: nil)
        }
        
         let alertActionSetLocation = UIAlertAction(title: "Change Location", style: .default) { _ in
            let torrent = self.torrents[indexPath.row]
            let setLocationAlert = UIAlertController(title: "Directory Location", message: "Enter Location: ", preferredStyle: .alert)
            setLocationAlert.addTextField(configurationHandler: { textField in
                textField.frame.size = CGSize(width: 300, height: 16)
                textField.text = torrent.downloadDir
            })
            setLocationAlert.addAction(UIAlertAction(title: "Move files", style: .default, handler: { _ in
                if setLocationAlert.textFields!.first!.text == nil {
                    setLocationAlert.textFields!.first!.becomeFirstResponder()
                    return
                }
                self.session.setLocation(forTorrent: trId, location: setLocationAlert.textFields!.first!.text!, move: true, withPriority: .veryHigh) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            displayErrorMessage(error!.localizedDescription, using: self.parent)
                        }
                    }
                }
            }))
            setLocationAlert.addAction(UIAlertAction(title: "Search files", style: .default, handler: { _ in
                if setLocationAlert.textFields!.first!.text == nil {
                    setLocationAlert.textFields!.first!.becomeFirstResponder()
                    return
                }
                self.session.setLocation(forTorrent: trId, location: setLocationAlert.textFields!.first!.text!, move: false, withPriority: .veryHigh) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            displayErrorMessage(error!.localizedDescription, using: self.parent)
                        }
                    }
                }
            }))
            setLocationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(setLocationAlert, animated: true, completion: nil)
            
        }
        
        let alertActionMoveUp = UIAlertAction(title: "Move Down", style: .default) { _ in
            self.session.move(torrents: [trId], to: .up, withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    } else {
                        let indexPathTo = IndexPath(row: indexPath.row < self.tableView.numberOfRows(inSection: indexPath.section) - 1 ?  indexPath.row + 1 : indexPath.row, section: indexPath.section)
                        self.tableView.moveRow(at: indexPath, to: indexPathTo)
                    }
                }
            }
        }
            
        let alertActionMoveTop = UIAlertAction(title: "Move Bottom", style: .default) { _ in
            self.session.move(torrents: [trId], to: .top, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        let lastRow = self.tableView.numberOfRows(inSection: indexPath.section) - 1
                        let indexPathTo = IndexPath(row: lastRow, section: indexPath.section)
                        self.tableView.moveRow(at: indexPath, to: indexPathTo)
                    }
                }
            })
        }
        
        let alertActionMoveDown = UIAlertAction(title: "Move Up", style: .default) { _ in
            self.session.move(torrents: [trId], to: .down, withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    let indexPathTo = IndexPath(row: indexPath.row > 0 ? indexPath.row - 1 : 0, section: indexPath.section)
                    self.tableView.moveRow(at: indexPath, to: indexPathTo)
    
                }
            }
        }
        
        let alertActionMoveBottom = UIAlertAction(title: "Move Top", style: .default) { _ in
            self.session.move(torrents: [trId], to: .bottom, withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        let indexPathTo = IndexPath(row: 0, section: indexPath.section)
                        self.tableView.moveRow(at: indexPath, to: indexPathTo)
                    }
                }
            }
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(alertActionStartNow)
        alertController.addAction(alertActionReannounce)
        alertController.addAction(alertActionVerify)
        alertController.addAction(alertActionRemove)
        alertController.addAction(alertActionSetLocation)
        alertController.addAction(alertActionMoveUp)
        alertController.addAction(alertActionMoveDown)
        alertController.addAction(alertActionMoveTop)
        alertController.addAction(alertActionMoveBottom)
            
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let popoverController = alertController.popoverPresentationController else {
                return
            }
            
            popoverController.sourceView = cell
            popoverController.sourceRect = cell.bounds
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    @objc func cancelEditing() {
        tableView.setEditing(false, animated: true)
        parent!.navigationItem.rightBarButtonItem = nil
        parent!.navigationItem.leftBarButtonItem = nil
        parent!.navigationItem.hidesBackButton = false
        parent!.navigationItem.rightBarButtonItems = (self.parent as! TorrentListController).rightBarButtons
        (parent as! TorrentListController).toolbar.isHidden = false
        (parent as! TorrentListController).toolbarEdit.isHidden = true
        tableView.reloadData()
    }
    
    
    @IBAction @objc func pauseTorrents(_ sender:UIBarButtonItem) {
        infoMessage = "Pausing Torrents..."
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
        var trIds: [trId] = []
       
        indexPaths.forEach({indexPath in
            let trInfo = torrents[indexPath.row]
            trIds.append(trInfo.trId)
        })
        session.stop(torrents: trIds, withPriority: .high) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
                else {
                    indexPaths.forEach({indexPath in
                        self.torrents[indexPath.row].status = .stopped
                        self.tableView.reloadRows(at: indexPaths, with: .automatic)
                    })
                    displayInfoMessage("Torrents sucessfully stopped", using: self.parent)
                }
            }
        }
        cancelEditing()
    }
    
    
    @IBAction @objc func resumeTorrents(_ sender: UIBarButtonItem) {
        infoMessage = "Resuming Torrents..."
        guard let indexPaths = tableView.indexPathsForSelectedRows else {return}
        var trIds: [Int] = []
        indexPaths.forEach({indexPath in
            let trInfo = torrents[indexPath.row]
            trIds.append(trInfo.trId)
        })
        session.start(torrents: trIds, withPriority: .high) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
                else {
                    displayInfoMessage("Torrents sucessfully started", using: self.parent)
                    self.session.getInfo(forTorrents: trIds, withPriority: .veryHigh) { (torrents, remove, error) in
                        DispatchQueue.main.async {
                            if error != nil {
                                displayErrorMessage(error!.localizedDescription, using: self.parent)
                            }
                            else {
                                for torrent in torrents! {
                                    guard let index = self.torrents.firstIndex(where: {$0.trId == torrent.trId}) else { continue}
                                    self.torrents[index] = torrent
                                }
                                self.tableView.reloadRows(at: indexPaths, with: .automatic)
                            }
                        }
                    }
                }
            }
        }

        cancelEditing()
    }
    
    
    @IBAction @objc func resumeNowTorrents(_ sender: UIBarButtonItem) {
        infoMessage = "Resuming Torrents Immediately..."
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
        var trIds: [Int] = []
        indexPaths.forEach({indexPath in
            let trInfo = torrents[indexPath.row]
            trIds.append(trInfo.trId)
        })
        session.startNow(torrents: trIds, withPriority: .high) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
                else {
                    displayInfoMessage("Torrents sucessfully started", using: self.parent)
                    self.session.getInfo(forTorrents: trIds, withPriority: .veryHigh) { (torrents, remove, error) in
                        DispatchQueue.main.async {
                            if error != nil {
                                displayErrorMessage(error!.localizedDescription, using: self.parent)
                            }
                            else {
                                for torrent in torrents! {
                                    guard let index = self.torrents.firstIndex(where: {$0.trId == torrent.trId}) else { continue}
                                    self.torrents[index] = torrent
                                }
                                self.tableView.reloadRows(at: indexPaths, with: .automatic)
                            }
                        }
                    }
                }
            }
        }
        
        cancelEditing()
    }
    
    
    @IBAction @objc func removeTorrents(_ sender:UIBarButtonItem) {
        
        guard let indexPaths = self.tableView.indexPathsForSelectedRows else {return}
        var trIds: [Int] = []
        if indexPaths.count > 0 {
            indexPaths.forEach({indexPath in
                let trInfo = torrents[indexPath.row]
                trIds.append(trInfo.trId)
            })
            let removeDataAlert = UIAlertController(title: "Delete Torrents", message: "Do you want to delete the torrent's data files?", preferredStyle: .alert)
            var deleteData: Bool = false
            removeDataAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                deleteData = true
            }))
            removeDataAlert.addAction(UIAlertAction(title: "No", style: .default, handler: {_ in
                deleteData = false
            }))
            removeDataAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
            self.present(removeDataAlert, animated: true, completion: {
                self.session.remove(torrents: trIds, deletingLocalData: deleteData, withPriority: .veryHigh) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            displayErrorMessage(error!.localizedDescription, using: self.parent)
                        }
                        else {
                            for trId in trIds {
                                self.torrents.removeAll(where: {$0.trId == trId})
                            }
                            self.tableView.deleteRows(at: indexPaths, with: .automatic)
                            displayInfoMessage("Torrents sucessfully deleted", using: self.parent)
                        }
                    }
                }
            })
            
        }
        cancelEditing()
    }
    
    
    @IBAction @objc func verifyTorrents(_ sender: UIBarButtonItem) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {return}
        var trIds: [Int] = []
        indexPaths.forEach({ indexPath in
            let trInfo = torrents[indexPath.row]
            trIds.append(trInfo.trId)
        })
        session.verify(torrents: trIds) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
                else {
                    displayInfoMessage("Torrents verification successfully started", using: self.parent)
                    self.session.getInfo(forTorrents: trIds, withPriority: .veryHigh) { (torrents, remove, error) in
                        DispatchQueue.main.async {
                            if error != nil {
                                displayErrorMessage(error!.localizedDescription, using: self.parent)
                            }
                            else {
                                for torrent in torrents! {
                                    guard let index = self.torrents.firstIndex(where: {$0.trId == torrent.trId}) else { continue}
                                    self.torrents[index] = torrent
                                }
                                self.tableView.reloadRows(at: indexPaths, with: .automatic)
                            }
                        }
                    }
                }
            }
        }
        cancelEditing()
    }
    
    
    @IBAction @objc func reannounceTorrents(_ sender: UIBarButtonItem) {
        infoMessage = "Updating Trackers..."
        let indexPaths = tableView.indexPathsForSelectedRows
        var trIds: [Int] = []
        if indexPaths != nil && (indexPaths?.count ?? 0) > 0 {
            indexPaths!.forEach({indexPath in
                let trInfo = torrents[indexPath.row]
                trIds.append(trInfo.trId)
            })
            session.reannounce(torrents: trIds) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        displayInfoMessage("Torrents successfully reannounced", using: self.parent)
                    }
                }
            }
        }
        cancelEditing()
    }
    
    
    func showFinishedTorrents() {
            
        self.lastTimeChecked = defaults.double(forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME)
        if self.lastTimeChecked == 0 {
            self.lastTimeChecked = Date().timeIntervalSince1970
        }
        
        
        let downloadedTorrents = torrents.filter({($0 ).dateDone?.timeIntervalSince1970 ?? 0 >= lastTimeChecked })
        downloadedTorrents.forEach({ trInfo in
            let content = UNMutableNotificationContent()
            content.title = String.localizedStringWithFormat("Torrent Finisheh")
            content.body = String.localizedStringWithFormat("\"%@\" have been downloaded.", trInfo.name)
            content.sound = UNNotificationSound.default
            content.userInfo = ["trId": trInfo.trId]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "Now", content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            DispatchQueue.global(qos: .default).async(execute: {
                center.add(request, withCompletionHandler: { error in
                    if error != nil {
                        os_log("Notification for torrent: %@ failed with Error: %@",trInfo.name!,error!.localizedDescription)
                    }
                })
            })
        })
        
        self.saveLastTimeChecked()
    }
    
    
    @objc func selectAllRows(_ sender:UIBarButtonItem) {
        tableView.beginUpdates()
        for section in 0..<tableView.numberOfSections {
            for row in 0..<tableView.numberOfRows(inSection: section) {
                let indexPath = self.tableView(tableView, willSelectRowAt: IndexPath(row: row, section: section))!
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
        tableView.endUpdates()
    }
    
    
    public func removeBlurEffect() {
        self.tableView.backgroundView = nil
        self.tableView.alpha = 1
        self.sectionHeaderView.backgroundColor = .systemBackground
         self.sectionHeaderView.alpha = 1
    }
    
    public func addBlurEffect(style effect: UIBlurEffect.Style) {
        let blurEffect = UIBlurEffect(style: effect)
        let viewVisualEffect = UIVisualEffectView(effect: blurEffect)
        viewVisualEffect.frame = self.tableView.bounds
        viewVisualEffect.layer.masksToBounds = true
        self.tableView.backgroundView = viewVisualEffect
        self.tableView.alpha = 0.7
        self.sectionHeaderView.backgroundColor = .clear
        self.sectionHeaderView.alpha = 0.3
    }
    
    // MARK: - Segues
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showTorrentDetails" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let torrent = torrents[indexPath.row]
                let controller = (segue.destination as! TorrentDetailsController)
                controller.torrent = torrent
                controller.torrentListController = parent as? TorrentListController
            }
        }
    }
    
    
    override public func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if tableView.isEditing && identifier == "showTorrentDetails" {
            return false
        }
        return true
    }
    

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return torrents.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TorrentListCell", for: indexPath) as! TorrentListCell
        
        let torrent = torrents[indexPath.row]
        torrents[indexPath.row].dataObject = indexPath
        cell.update(withTRInfo: torrent)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressRecognizer.minimumPressDuration = 1.0
        cell.contentView.addGestureRecognizer(longPressRecognizer)
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sectionHeaderView
    }
    
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.isEditing {
            tableView.cellForRow(at: indexPath)?.selectionStyle = .default
        }
        else {
            tableView.cellForRow(at: indexPath)?.selectionStyle = .none
        }
        return indexPath
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
        
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let trInfo = torrents[sourceIndexPath.row]
        let indexSource = categorization.items.firstIndex(of: trInfo)
        let toTrInfo = torrents[destinationIndexPath.row]
        let toPos = toTrInfo.queuePosition
//        let indexDest = categorization.items.firstIndex(of: toTrInfo)
        categorization.items[indexSource!].queuePosition = toPos
//        categorization.items.move(fromOffsets: IndexSet(integer: indexSource!), toOffset: indexDest!)
        let rpcArgument = [JSONKeys.queuePosition: toPos]
        session.setFields(rpcArgument, forTorrents: [trInfo.trId], withPriority: .veryHigh) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
            }
        }
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let removeAction = UIContextualAction(style: .destructive, title: "Remove", handler: {action,view,completion in
            let trInfo = self.torrents[indexPath.row]
            self.session.remove(torrents: [trInfo.trId], deletingLocalData: false, withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        completion(false)
                    }
                    else {
                        displayInfoMessage("Torrent successfully deleted", using: self.parent)
                        completion(true)
                    }
                }
            }
        })
        removeAction.image = UIImage(systemName: "trash")
        let removeWithDataAction = UIContextualAction(style: .destructive, title: "Remove With Data", handler: {action,view,completion in
            let trInfo = self.torrents[indexPath.row]
            self.session.remove(torrents: [trInfo.trId], deletingLocalData: true, withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        completion(false)
                    }
                    else {
                        displayInfoMessage("Torrents successfully deleted", using: self.parent)
                        completion(true)
                    }
                }
            }
        })
        removeWithDataAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [removeAction, removeWithDataAction])
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let startNowAction = UIContextualAction(style: .normal, title: "Start Now", handler: {action,view,completion in
            let trInfo = self.torrents[indexPath.row]
            self.session.startNow(torrents: [trInfo.trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        completion(false)
                    }
                    else {
                        self.updateData()
                        displayInfoMessage("Torrents sucessfully started", using: self.parent)
                        completion(true)
                    }
                }
            }
        })
        startNowAction.image = UIImage(systemName: "livephoto.play")
        startNowAction.backgroundColor = .systemGreen
        let reannounceAction = UIContextualAction(style: .normal, title: "Reannounce", handler: {action,view,completion in
            let trInfo = self.torrents[indexPath.row]
            self.session.reannounce(torrents: [trInfo.trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        completion(false)
                    }
                    else {
                        self.updateData()
                        completion(true)
                    }
                }
            }
        })
        reannounceAction.image = UIImage(systemName: "arrow.clockwise.circle")
        reannounceAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [startNowAction, reannounceAction])
    }

// MARK: - UITableViewDragDelegate
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let itemProvider = NSItemProvider(object: torrents[indexPath.row])
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = torrents[indexPath.row]
        session.localContext = indexPath
        return [ dragItem ]
    }

    
// MARK: - UITableViewDropDelegate
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        //return session.canLoadObjects(ofClass: TRInfo.self)
        return true
    }
    
    
   func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // The .move operation is available only for dragging within a single app.
        if tableView.hasActiveDrag {
            if session.items.count > 1 {
                return UITableViewDropProposal(operation: .cancel)
            } else {
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
        } else {
            return UITableViewDropProposal(operation: .cancel)
        }
    }
    
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        var trIds = [TrId]()
        var indexSet = IndexSet()
        tableView.beginUpdates()
        let destPos = torrents[destinationIndexPath.row].queuePosition
        var i: Int = 0
        for item in coordinator.items {
            i += 1
            guard let sourceIndexPath = item.sourceIndexPath else {continue}
            let trInfo = item.dragItem.localObject as! Torrent
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            if let index = torrents.firstIndex(of: trInfo) {
                torrents[index].queuePosition = destPos + i
                indexSet.insert(index)
            }
            trIds.append(trInfo.trId)
        }
//        torrents.move(fromOffsets: indexSet, toOffset: destinationIndexPath.row)
        tableView.endUpdates()
        let rpcArgument = [JSONKeys.queuePosition: destPos]
        if trIds.count > 0 {
            session.setFields(rpcArgument, forTorrents: trIds, withPriority: .high) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                    }
                    else {
                        displayInfoMessage("Torrents successfully moved", using: self.parent)
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    /// Notification for when download progress has changed.
    static let ChangeIconSpeedColor = Notification.Name(rawValue: "ChangeIconSpeedColor")
}
