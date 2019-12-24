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
    
    var torrents: Array<Torrent> {
        return self.categorization.itemsForSelectedCategory as! Array<Torrent>
    }
    
    var sessionConfig: SessionConfig!
    
    private var lastTimeChecked: TimeInterval = 0
    
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
        self.tableView.remembersLastFocusedIndexPath = true

        freeSpaceIcon.isHidden = !RPCServerConfig.sharedConfig!.showFreeSpace
        freeSpaceLabel.isHidden = !RPCServerConfig.sharedConfig!.showFreeSpace
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeIconSpeedColor(_:)),
                                               name: .ChangeIconSpeedColor, object: nil)
        let decoder = JSONDecoder()
        guard let data = defaults.data(forKey: TORRENT_LIST),
            let torrents = try? decoder.decode([Torrent].self, from: data) else { return }
        self.categorization.setItems(torrents)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categorization.registerTableView(self.tableView, forSection: 0)
    }

    override public func viewDidAppear(_ animated: Bool) {
        firstTime = true
        super.viewDidAppear(animated)
        lastTimeChecked = defaults.double(forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME)
        if lastTimeChecked == 0 {
            lastTimeChecked = Date().timeIntervalSince1970 - 180
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        categorization.deregisterTableView(tableView, forSection: 0)
        let encoder = JSONEncoder()
        let highRange = torrents.count < 1000 ? torrents.count : 1000
        let data = try? encoder.encode(Array(torrents[0..<highRange]))
        defaults.set(data, forKey: TORRENT_LIST)
        defaults.synchronize()
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
            self.tableView.refreshControl!.beginRefreshing()
            firstTime = true
            if !globalRefreshTimer.isValid {
                try? RPCSession.shared?.restart()
                startRefresh()
                self.tableView.refreshControl!.endRefreshing()
                return
            }
            self.tableView.refreshControl!.endRefreshing()
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
                    // if All Torrents are received, just assign the array as categorization items
                    self.categorization.setItems(torrents)
                    self.torrentsCount.text = String(self.torrents.count)
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
                    if sessionConfig.speedLimitDownEnabled {
                        self.downloadSpeedIcon.tintColor = .red
                        self.downloadSpeed.textColor = .red
                    }
                    else if sessionConfig.speedLimitUpEnabled {
                        self.uploadSpeedIcon.tintColor = .red
                        self.uploadSpeed.textColor = .red
                    }
                    if RPCServerConfig.sharedConfig!.showFreeSpace {
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
            let priority :Operation.QueuePriority  = sender == nil ? .veryHigh : .normal
            session.getInfo(forTorrents: RecentlyActive, withPriority: priority) { (torrents, removed, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        return
                    }
                    guard let torrents = torrents else {return}
                    if let removed = removed {
                        self.categorization.removeItems(where: { removed.contains($0.trId) })
                    }
                    // if All Torrents are received, just assign the array as categorization items
                    self.categorization.updateItems(with: torrents)
                    self.torrentsCount.text = String(self.torrents.count)
                    self.errorMessage = nil
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
    
    @IBAction @objc func startAllTorrents(_ sender: UIBarButtonItem) {
        displayInfoMessage("Starting All Torrents...", using: self.parent)
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
        displayInfoMessage("Stopping All Torrents...", using: self.parent)
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
    
    
    @IBAction public func longPress(_ sender: UIGestureRecognizer) {
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
                        self.updateData()
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
                                else {
                                    self.updateData()
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
                            self.categorization.removeItems(where: { $0.trId == trId })
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
                            self.categorization.removeItems(where: { $0.trId == trId })
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
    
    
    @IBAction @objc func pauseTorrents(_ sender: Any) {
        var trIds: [trId] = []
        if let sender = sender as? UIButton {
            guard let torrent = sender.dataObject as? Torrent else { return }
            trIds = [torrent.trId]
            sender.isEnabled = false
        } else if sender is UIBarButtonItem {
            displayInfoMessage("Pausing Torrent(s)", using: self.parent)
            guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
            indexPaths.forEach({indexPath in
                let trInfo = torrents[indexPath.row]
                trIds.append(trInfo.trId)
            })
        }
        session.stop(torrents: trIds, withPriority: .veryHigh) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                } else {
                    displayInfoMessage("Torrent(s) sucessfully stopped", using: self.parent)
                }
            }
        }
        if tableView.isEditing {
            cancelEditing()
        }
    }
    
    
    @IBAction @objc public func resumeTorrents(_ sender: Any) {
        var trIds: [trId] = []
        if let sender = sender as? UIButton {
            guard let torrent = sender.dataObject as? Torrent else { return }
            trIds = [torrent.trId]
            DispatchQueue.main.async {
                sender.isEnabled = false
            }
        } else if sender is UIBarButtonItem {
            displayInfoMessage("Resuming Torrent(s)", using: self.parent)
            guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
            indexPaths.forEach({indexPath in
                let trInfo = torrents[indexPath.row]
                trIds.append(trInfo.trId)
            })
        }
        session.start(torrents: trIds, withPriority: .veryHigh) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
                else {
                    displayInfoMessage("Torrent(s) sucessfully started", using: self.parent)
                }
            }
        }
        if tableView.isEditing {
            cancelEditing()
        }
    }
    
    
    @IBAction @objc func resumeNowTorrents(_ sender: UIBarButtonItem) {
        displayInfoMessage("Resuming Torrents Immediately...", using: self.parent)
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
                                self.categorization.updateItems(with: torrents!)
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
                            self.categorization.removeItems(where: { trIds.contains($0.trId) })
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
                                self.categorization.updateItems(with: torrents!)
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
            
        if self.lastTimeChecked == 0  {
            lastTimeChecked = TorrentTableController.getLastTimeChecked()
        }
        let lastTime = Date().timeIntervalSince1970
        let downloadedTorrents = torrents.filter({$0.dateDone?.timeIntervalSince1970 ?? 0 >= (lastTimeChecked - 7) })
        downloadedTorrents.forEach({ trInfo in
            
            let content = UNMutableNotificationContent()
            content.title = String.localizedStringWithFormat("Torrent Finisheh")
            content.body = String.localizedStringWithFormat("\"%@\" have been downloaded.", trInfo.name)
            content.sound = UNNotificationSound.default
            content.userInfo = ["trId": trInfo.trId]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "Now", content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            DispatchQueue.main.async(execute: {
                center.add(request, withCompletionHandler: { error in
                    if error != nil {
                        os_log("Notification for torrent: %@ failed with Error: %@",trInfo.name!,error!.localizedDescription)
                    }
                })
            })
        })
        self.lastTimeChecked = lastTime
        TorrentTableController.saveLastTimeChecked(lastTime)
        
    }
    
    
    public class func getLastTimeChecked() -> TimeInterval {
        let store = NSUbiquitousKeyValueStore.default
        let defaults = UserDefaults(suiteName: TR_URL_DEFAULTS)
        var lastTimeChecked: TimeInterval
        lastTimeChecked = store.double(forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME)
        if lastTimeChecked == 0 {
            lastTimeChecked = defaults?.double(forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME) ?? Date().timeIntervalSince1970
            if lastTimeChecked == 0 {
                lastTimeChecked = Date().timeIntervalSince1970
            }
        }
        return lastTimeChecked
    }
    
    
    public class func saveLastTimeChecked(_ lastTimeChecked: TimeInterval = Date().timeIntervalSince1970) {
        let store = NSUbiquitousKeyValueStore.default
        let defaults = UserDefaults(suiteName: TR_URL_DEFAULTS)
        store.set(lastTimeChecked, forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME)
        store.synchronize()
        defaults?.set(lastTimeChecked, forKey: USERDEFAULTS_BGFETCH_KEY_LAST_TIME)
        defaults?.synchronize()
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
        return self.torrents.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TorrentListCell", for: indexPath) as? TorrentListCell else { return UITableViewCell() }
        
        let torrent = torrents[indexPath.row]
        torrents[indexPath.row].dataObject = indexPath
        cell.update(withItem: torrent)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressRecognizer.dataObject = torrent
        longPressRecognizer.minimumPressDuration = 0.8
        longPressRecognizer.cancelsTouchesInView = false
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
        let toTrInfo = torrents[destinationIndexPath.row]
        let toPos = toTrInfo.queuePosition
        trInfo.queuePosition = toPos
        let rpcArgument = [JSONKeys.queuePosition: toPos]
        session.setFields(rpcArgument, forTorrents: [trInfo.trId], withPriority: .veryHigh) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.parent)
                }
            }
        }
        self.categorization.moveItem(from: sourceIndexPath.row, to: destinationIndexPath.row)
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
                        self.categorization.removeItems(where: { $0.trId == trInfo.trId })
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
                        self.categorization.removeItems(where: { $0.trId == trInfo.trId })
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
                        self.session.getInfo(forTorrents: [trInfo.trId], withPriority: .veryHigh, andCompletionHandler: {torrents, removed, error in
                            DispatchQueue.main.async {
                                guard let torrents = torrents else { return }
                                self.categorization.updateItems(with: torrents)
                            }
                        })
                        displayInfoMessage("Torrents sucessfully started", using: self.parent)
                        completion(true)
                    }
                }
            }
        })
        startNowAction.image = UIImage(named: "iconPlayNow")
        startNowAction.backgroundColor = .systemGreen
        
        let verifyAction = UIContextualAction(style: .normal, title: "Verify", handler: {action,view,completion in
            let trInfo = self.torrents[indexPath.row]
            self.session.verify(torrents: [trInfo.trId], withPriority: .veryHigh) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.parent)
                        completion(false)
                    }
                    else {
                        completion(true)
                    }
                }
            }
        })
        verifyAction.image = UIImage(systemName: "checkmark")
        verifyAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [startNowAction, verifyAction])
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
    
    }
}

extension Notification.Name {
    /// Notification to notify that download/upload speed limits has been changed.
    static let ChangeIconSpeedColor = Notification.Name(rawValue: "ChangeIconSpeedColor")
}
