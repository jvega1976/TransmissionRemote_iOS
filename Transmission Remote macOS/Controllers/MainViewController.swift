//
//  MainViewController.swift
//  Transmission Remote
//
//  Created by  on 12/13/19.
//

import Cocoa
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
    case progress = "Progress"
    case download = "Download"
    case priority = "Priority"
    
    static var allValues: Array<String> {
        return SortField.allCases.map{ $0.rawValue }
    }
}

public enum SortDirection: String {
    case asc = "Ascendent"
    case desc = "Descendent"
}


class MainViewController: NSViewController {

    // MARK:- DockTile variables
    var dockTile: NSDockTile!
    var dockView: DockView!
    
    // MARK:- View Outlets
    @IBOutlet weak var toggleButton: NSButton!
    @IBOutlet weak var mainView: NSVisualEffectView!
    @IBOutlet weak var torrentDetailView: NSView!
    @IBOutlet weak var torrentListView: NSVisualEffectView!
    @IBOutlet weak var torrentTableView: NSTableView!
    @IBOutlet var torrentArrayController: NSArrayController!
    
    @objc dynamic var torrentFilesController: TorrentFilesController!
    
    // MARK:- TabView right TabBar
    dynamic var torrentDetailsController: TorrentDetailsController!
    @IBOutlet weak var torrentTabViewButtons: NSStackView!
    @IBOutlet weak var torrentContainerView: NSView!
    
    @IBOutlet weak var toggleSideBarButton: NSButton!
    var torrentDetailViewSize: CGSize!
    
    var tabButtons: [NSButton]!
    var oldSelection: Int = 0
    var newSelection: Int = 0
    
    // MARK:- Status Bar Outlets
    @IBOutlet weak var serverUrlLabel: NSTextField!
    @IBOutlet weak var downloadSpeedIcon: IconHalfCloud!
    @IBOutlet weak var downloadSpeedLabel: NSTextField!
    @IBOutlet weak var uploadSpeedIcon: IconHalfCloud!
    @IBOutlet weak var uploadSpeedLabel: NSTextField!
    @IBOutlet weak var freeSpaceLabel: NSTextField!
    @IBOutlet weak var freeSpaceIcon: NSImageView!
    
    // MARK: - Table Row Selection variables
    @objc dynamic var selectedRows = IndexSet()
    
    // MARK:- Refresh Timer variables
    var refreshTimer: Timer!
    var firstTime: Bool = true
    
    var isEditing: Bool = false
    
    // MARK:- RPC session variables
    @objc dynamic var serverConfig: RPCServerConfig? {
        set(newConfig) {
            RPCServerConfig.sharedConfig = newConfig
            self.serverConfigChangeHandler()
        }
        get {
            return RPCServerConfig.sharedConfig
        }
    }
    
    @objc dynamic var session: RPCSession? {
        get {
            return RPCSession.shared
        }
        set(newSession) {
            RPCSession.shared?.stopRequests()
            self.firstTime = true
            RPCSession.shared = newSession
        }
    }
    
    // MARK:- Torrent Categorization variables
    dynamic var categorization: TorrentCategorization = {
        return TorrentCategorization.shared
    }()
    
    @objc dynamic var torrents: [Torrent] {
        get {
            return self.categorization.itemsForSelectedCategory as! [Torrent]
        }
        set {
            self.categorization.setItems(newValue)
        }
    }
    
    
    @objc dynamic var selectionIndexes: IndexSet! {
        didSet {
         /*for i in (oldValue ?? IndexSet()).subtracting(self.selectionIndexes) {
                guard let cell = torrentTableView.view(atColumn: 0, row: i, makeIfNecessary: false) as? TorrentCellView else { continue }
                cell.isSelected = false
            }
            for i in self.selectionIndexes.subtracting(oldValue ?? IndexSet()) {
                guard let cell = torrentTableView.view(atColumn: 0, row: i, makeIfNecessary: false) as? TorrentCellView else { continue }
                cell.isSelected = true
            }*/
            categorization.selectionIndexes = self.selectionIndexes
        }
    }
    
    dynamic var sessionConfig: SessionConfig!
    dynamic var sessionStats: SessionStats!
    
    
    private var observerContext = 0
    
// MARK:- View Controller methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        guard let serverConfig = ServerConfigDB.shared.defaultConfig else {
            let error = NSError(domain: "TransmissionRemote", code: 999, userInfo: [NSLocalizedDescriptionKey: "Please, define a Server as default or select one from the available list"])
                    self.presentError(error)
                    return }
        self.serverConfig = serverConfig
        NotificationCenter.default.addObserver(self, selector: #selector(serverConfigChangeHandler(_:)), name: .ServerConfigChanged, object: nil)
        self.dockView = DockView()
        self.dockTile = NSApp.dockTile
        self.dockTile.contentView = self.dockView
        self.dockTile.display()
//       categorization.addObserver(self, forKeyPath: #keyPath(TorrentCategorization.itemsForSelectedCategory), options: [.prior,.new], context: &observerContext)
        self.selectionIndexes = categorization.selectionIndexes
        self.torrentTableView.registerForDraggedTypes([.string,.fileContents])
        self.categorization.registerTableView(self.torrentTableView, forColumns: IndexSet(integer: 0))
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &observerContext && object is TorrentCategorization,
            let kind = NSKeyValueChange(rawValue: change?[NSKeyValueChangeKey.kindKey] as! UInt) {
           
            if change?[NSKeyValueChangeKey.notificationIsPriorKey] as? Bool ?? false {
                if let indexes = change?[NSKeyValueChangeKey.indexesKey] as? NSIndexSet {
                    self.willChange(kind, valuesAt: indexes as IndexSet, forKey: #keyPath(torrents))
                } else {
                    self.willChangeValue(forKey: #keyPath(torrents))
                }
            } else {
                if let indexes = change?[NSKeyValueChangeKey.indexesKey] as? NSIndexSet {
                    self.didChange(kind, valuesAt: indexes as IndexSet, forKey: #keyPath(torrents))
                } else {
                    self.didChangeValue(forKey: #keyPath(torrents))
                }
            }
        }
    }
 
    override func viewDidAppear() {
        super.viewDidAppear()
        tabButtons[0].state = .on
        self.torrentDetailViewSize = CGSize(width: max(self.torrentDetailView.bounds.size.width,544), height: self.torrentDetailView.bounds.size.height)
        self.toggleContainerView(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tabButtons = (torrentTabViewButtons.arrangedSubviews.filter { $0 is NSButton } as! [NSButton])
    }
    
// MARK:- Events Handlers
    
    @objc func updateDataHandler() {
        if firstTime {
            self.session?.getInfo(forTorrents: nil, withPriority: .veryHigh) { (torrents, removed, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        self.presentError(error!)
                        self.firstTime = true
                        self.updateDataHandler()
                        return
                    }
                    guard let torrents = torrents else {return}
                    self.categorization.setItems(torrents)
                }
            }
            session?.getSessionConfig(withPriority: .veryHigh) { (sessionConfig, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        self.presentError(error!)
                        return
                    }
                    guard let sessionConfig = sessionConfig else {return}
                    self.sessionConfig = sessionConfig
                    if sessionConfig.speedLimitDownEnabled {
                        self.downloadSpeedIcon.tintColor = .red
                        self.downloadSpeedLabel.textColor = .red
                    }
                    else if sessionConfig.speedLimitUpEnabled {
                        self.uploadSpeedIcon.tintColor = .red
                        self.uploadSpeedLabel.textColor = .red
                    }
                    if RPCServerConfig.sharedConfig!.showFreeSpace {
                        self.freeSpaceLabel.isHidden = false
                        self.freeSpaceIcon.isHidden = false
                        self.session?.getFreeSpace(availableIn: sessionConfig.downloadDir) { (freeSpace, error) in
                            DispatchQueue.main.async {
                                if error != nil {
                                    self.presentError(error!)
                                } else {
                                    guard let freeSpace = freeSpace else { return }
                                    self.freeSpaceLabel.stringValue = formatByteCount(freeSpace)
                                }
                            }
                        }
                    }
                }
            }
            firstTime = false
        } else {
            session?.getInfo(forTorrents: RecentlyActive) { (torrents, removed, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        self.presentError(error!)
                        return
                    }
                    guard let torrents = torrents else {return}
                    if !(removed?.isEmpty ?? true)  {
                        self.categorization.removeItems(where: {removed!.contains($0.trId)})
                    }
                    self.categorization.updateItems(with: torrents)
                }
            }
        }
        session?.getSessionStats { (sessionStats, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.presentError(error!)
                    return
                }
                guard let stats = sessionStats else {return}
                let downloadRate = formatByteRate(stats.downloadSpeed)
                self.downloadSpeedLabel.stringValue = downloadRate
                self.dockView.downloadLabel.stringValue = "↓" + downloadRate
                if stats.downloadSpeed > 0 {
                   self.downloadSpeedIcon.playDownloadAnimation()
                }
                else {
                    self.downloadSpeedIcon.stopDownloadAnimation()
                }
                let uploadRate = formatByteRate(stats.uploadSpeed)
                self.uploadSpeedLabel.stringValue = uploadRate
                self.dockView.uploadLabel.stringValue = "↑" + uploadRate
                self.dockTile.display()
                if stats.uploadSpeed > 0 {
                    self.uploadSpeedIcon.playUploadAnimation()
                }
                else {
                    self.uploadSpeedIcon.stopUploadAnimation()
                }
            }
        }
    }
    
    @objc func serverConfigChangeHandler(_ notification: Notification? = nil) {
        
        if let controller = notification?.object as? NSViewController {
            self.dismiss(controller)
        }
        
        if self.session != nil {
            self.session!.stopRequests()
            if refreshTimer.isValid {
                refreshTimer.invalidate()
            }
        }
        if self.serverConfig != nil {
            do {
                guard let session = try RPCSession(withURL: self.serverConfig!.configURL!, andTimeout: self.serverConfig!.requestTimeout) else { return }
                self.session = session
                self.updateDataHandler()
                self.refreshTimer = Timer.scheduledTimer(timeInterval: serverConfig!.refreshTimeout, target: self, selector: #selector(updateDataHandler), userInfo: nil, repeats: true)
                self.serverUrlLabel.stringValue = self.serverConfig!.urlString
            } catch {
                self.session = nil
                self.categorization.setItems([])
                self.serverUrlLabel.stringValue = error.localizedDescription
                self.presentError(error)
            }
            
        } else {
            self.session = nil
            self.serverUrlLabel.stringValue = ""
            if refreshTimer.isValid {
                refreshTimer.invalidate()
            }
        }
    }
    
    @IBAction func selectedButton(_ sender: NSButton) {
        tabButtons[oldSelection].state = .off
        self.newSelection = tabButtons.firstIndex {button in button.tag == sender.tag} ?? 0
        torrentDetailsController.selectedTabViewItemIndex = sender.tag
        tabButtons[newSelection].state = .on
        //sender.state = .on
        oldSelection = newSelection
    }
    
    @IBAction @objc func toggleContainerView(_ sender: Any? = nil ) {
        //let size = self.mainView.bounds.size
        if self.torrentDetailView.isHidden {
            self.mainView.frame.size.width += (self.torrentDetailViewSize.width - 56)
            self.mainView.bounds.size.width = self.mainView.frame.size.width
            self.torrentDetailView.frame.size.width =  (self.torrentDetailViewSize.width - 56)
            self.torrentDetailView.bounds.size.width = self.torrentDetailView.frame.size.width
            self.torrentDetailView.isHidden = !self.torrentDetailView.isHidden
            self.torrentListView.frame.size.width = self.mainView.bounds.size.width - (self.torrentDetailViewSize.width - 56)
            self.torrentListView.bounds.size.width = self.torrentListView.frame.size.width
        } else {
            self.torrentDetailView.isHidden = !self.torrentDetailView.isHidden
            self.torrentDetailViewSize = self.torrentDetailView.bounds.size
            self.torrentDetailView.frame.size.width = 0.0
            self.torrentDetailView.bounds.size.width = 0.0
            self.mainView.frame.size.width -= (self.torrentDetailViewSize.width + 56)
            self.mainView.bounds.size.width = self.mainView.frame.size.width
        }
        self.view.window?.setContentSize(self.mainView.bounds.size)
        self.mainView.needsLayout = true
        toggleSideBarButton.state = self.torrentDetailView.isHidden ? .off : .on
        self.mainView.needsDisplay = true
        
    }
    
// MARK:- Toolbar Actions
    
    @IBAction @objc func serverConfigToolbarAction(_ sender: NSSegmentedControl) {
        let selectedSegment = sender.selectedTag()
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        switch selectedSegment {
            case 0:
                guard let controller = storyboard.instantiateController(withIdentifier: "ServerConfigList") as? ServerConfigListController else { return }
                self.present(controller, asPopoverRelativeTo: controller.view.frame, of: sender, preferredEdge: .minY, behavior: .transient)
            case 1:
                guard let controller = storyboard.instantiateController(withIdentifier: "ServerConfigSetup") as? ServerConfigController else { return }
                self.presentAsSheet(controller)
            default: break
        }
    }
    
    
    @IBAction @objc func startTorrent(_ sender: NSButton) {
        var torrentsId = [trId]()
        if let trId = sender.dataObject as? Int {
            torrentsId.append(trId)
            sender.isEnabled = false
        } else  {
            let selectedRows = torrentArrayController.selectionIndexes
            for row in selectedRows {
                torrentsId.append(torrents[row].trId)
            }
        }
        if !torrentsId.isEmpty {
            session?.start(torrents: torrentsId, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    } else {
                        InfoMessage.displayInfoMessage("Torrent(s) successful started", in: self.view)
                    }
                }
            })
        }
    }
    
    @IBAction @objc func startNowTorrent(_ sender: NSButton) {
        let selectedRows = torrentTableView.selectedRowIndexes
        var torrentsId = [trId]()
        for row in selectedRows {
            torrentsId.append(torrents[row].trId)
        }
        if !torrentsId.isEmpty {
            session?.startNow(torrents: torrentsId, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    } else {
                        InfoMessage.displayInfoMessage("Torrent(s) successful started", in: self.view)
                    }
                }
            })
        }
    }
    
    
    @IBAction @objc func pauseTorrent(_ sender: NSButton) {
        var torrentsId = [trId]()
        if let trId = sender.dataObject as? Int {
            torrentsId.append(trId)
            sender.isEnabled = false
        } else  {
            let selectedRows = torrentTableView.selectedRowIndexes
            for row in selectedRows {
                torrentsId.append(torrents[row].trId)
            }
        }
        if !torrentsId.isEmpty {
            session?.stop(torrents: torrentsId, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    } else {
                        InfoMessage.displayInfoMessage("Torrent(s) successful paused", in: self.view)
                    }
                }
            })
        }
    }
    
    
    @IBAction @objc func reannounceTorrent(_ sender: NSToolbarItem) {
        let selectedRows = torrentTableView.selectedRowIndexes
        var torrentsId = [trId]()
        for row in selectedRows {
            torrentsId.append(torrents[row].trId)
        }
        if !torrentsId.isEmpty {
            session?.reannounce(torrents: torrentsId, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    } else {
                        InfoMessage.displayInfoMessage("Torrent(s) successful reannounced", in: self.view)
                    }
                }
            })
        }
    }
    
    
    @IBAction @objc func verifyTorrent(_ sender: NSToolbarItem) {
        let selectedRows = torrentTableView.selectedRowIndexes
        var torrentsId = [trId]()
        for row in selectedRows {
            torrentsId.append(torrents[row].trId)
        }
        if !torrentsId.isEmpty {
            session?.verify(torrents: torrentsId, withPriority: .veryHigh, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    } else {
                        self.updateDataHandler()
                    }
                }
            })
        }
    }
    
    @IBAction func removeTorrent(_ sender: NSPopUpButton) {
        let selectedOption = sender.selectedTag()
        let selectedRows = torrentTableView.selectedRowIndexes
        var torrentsId = [trId]()
        for row in selectedRows {
            torrentsId.append(torrents[row].trId)
        }
        switch selectedOption {
            case 1:
                session?.remove(torrents: torrentsId, deletingLocalData: false, withPriority: .veryHigh, completionHandler: { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                        }
                    }
                })
            case 2:
                session?.remove(torrents: torrentsId, deletingLocalData: true, withPriority: .veryHigh, completionHandler: { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                        }
                    }
                })
            default:
            break
        }
    }
    
    @IBAction @objc func sortTorrents(_ sender: NSPopUpButton) {
        let selectedItemTag = sender.selectedTag()
        if selectedItemTag < 20 {
            let newSelection = sender.indexOfSelectedItem
            guard let prevSelection = sender.itemArray.firstIndex(where: { 0...20 ~= $0.tag  &&  $0.state == .on }) else { return }
            sender.item(at: prevSelection)!.state = .off
            sender.item(at: newSelection)!.state = .on
        } else {
            let newSelection = sender.indexOfSelectedItem
            guard let prevSelection = sender.itemArray.firstIndex(where: { $0.tag >= 20 &&  $0.state == .on }) else { return }
            sender.item(at: prevSelection)!.state = .off
            sender.item(at: newSelection)!.state = .on
        }
        let direction =  SortDirection(rawValue: sender.itemArray.first(where: {$0.tag >= 20 && $0.state == .on })!.title)
        let fieldName = SortField(rawValue: sender.itemArray.first(where: {0...20 ~= $0.tag && $0.state == .on })!.title)
        
        switch (fieldName, direction) {
            case (.dateAdded,.asc):
            self.categorization.sortPredicate = { $0.dateAdded! < $1.dateAdded! }
            case (.dateAdded,.desc):
            self.categorization.sortPredicate = { $0.dateAdded! > $1.dateAdded! }
            case (.dateCompleted,.asc):
            self.categorization.sortPredicate = { $0.dateDone! < $1.dateDone! }
            case (.dateCompleted,.desc):
            self.categorization.sortPredicate = { $0.dateDone! > $1.dateDone! }
            case (.name,.asc):
            self.categorization.sortPredicate = { $0.name < $1.name }
            case (.name,.desc):
            self.categorization.sortPredicate = { $0.name > $1.name }
            case (.eta,.asc):
            self.categorization.sortPredicate = { $0.eta < $1.eta }
            case (.eta,.desc):
            self.categorization.sortPredicate = { $0.eta > $1.eta }
            case (.size,.asc):
            self.categorization.sortPredicate = { $0.totalSize < $1.totalSize }
            case (.size,.desc):
            self.categorization.sortPredicate = { $0.totalSize > $1.totalSize }
            case (.percentage,.asc):
            self.categorization.sortPredicate = { $0.percentsDone < $1.percentsDone }
            case (.percentage,.desc):
            self.categorization.sortPredicate = { $0.percentsDone > $1.percentsDone }
            case (.downSpeed,.asc):
            self.categorization.sortPredicate = { $0.downloadRate < $1.downloadRate }
            case (.downSpeed,.desc):
            self.categorization.sortPredicate = { $0.downloadRate > $1.downloadRate }
            case (.upSpeed,.asc):
            self.categorization.sortPredicate = { $0.uploadRate < $1.uploadRate }
            case (.upSpeed,.desc):
            self.categorization.sortPredicate = { $0.uploadRate > $1.uploadRate }
            case (.seeds,.asc):
            self.categorization.sortPredicate = { $0.peersGettingFromUs < $1.peersGettingFromUs }
            case (.seeds,.desc):
            self.categorization.sortPredicate = { $0.peersGettingFromUs > $1.peersGettingFromUs }
            case (.peers,.asc):
            self.categorization.sortPredicate = { $0.peersSendingToUs < $1.peersSendingToUs }
            case (.peers,.desc):
            self.categorization.sortPredicate = { $0.peersSendingToUs > $1.peersSendingToUs }
            case (.queuePos,.asc):
            self.categorization.sortPredicate = { $0.queuePosition < $1.queuePosition }
            case (.queuePos,.desc):
            self.categorization.sortPredicate = { $0.queuePosition > $1.queuePosition }
            default:
                break
        }
    }
    
    @IBAction @objc public func sortFiles(_ sender: NSPopUpButton) {
        let selectedItemTag = sender.selectedTag()
        if selectedItemTag < 20 {
            let newSelection = sender.indexOfSelectedItem
            guard let prevSelection = sender.itemArray.firstIndex(where: { 0...20 ~= $0.tag  &&  $0.state == .on }) else { return }
            sender.item(at: prevSelection)!.state = .off
            sender.item(at: newSelection)!.state = .on
        } else {
            let newSelection = sender.indexOfSelectedItem
            guard let prevSelection = sender.itemArray.firstIndex(where: { $0.tag >= 20 &&  $0.state == .on }) else { return }
            sender.item(at: prevSelection)!.state = .off
            sender.item(at: newSelection)!.state = .on
        }
        let direction =  SortDirection(rawValue: sender.itemArray.first(where: {$0.tag >= 20 && $0.state == .on })!.title)
        let fieldName = SortField(rawValue: sender.itemArray.first(where: {0...20 ~= $0.tag && $0.state == .on })!.title)
        
        switch (fieldName, direction) {
            case (.name,.asc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "name", ascending: true)]
            case (.name,.desc):
            self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "name", ascending: false)]
            case (.size,.asc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "size", ascending: true)]
            case (.size,.desc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "size", ascending: false)]
            case (.progress,.asc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "downloadProgressDouble", ascending: true)]
            case (.progress,.desc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "downloadProgressDouble", ascending: false)]
            case (.priority,.asc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "priorityInteger", ascending: true)]
            case (.priority,.desc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "priorityInteger", ascending: false)]
            case (.download,.asc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "isWanted", ascending: true)]
            case (.download,.desc):
                self.torrentFilesController.sortCriteria = [NSSortDescriptor(key: "isWanted", ascending: false)]
            default: break
        }
    }
    
// MARK:- Segues
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "tabViewController" {
            self.torrentDetailsController = segue.destinationController as? TorrentDetailsController
            self.torrentDetailsController.mainController = self
            self.torrentDetailsController.view.frame = self.torrentContainerView.bounds
        }
    }
    
}

// MARK: - Protocols TableViewDataSource and TableViewDelegate

extension MainViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.torrents.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return torrents[row]
    }
 
    
    /// TableCellView
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        /*let column = tableView.tableColumns.firstIndex(of: tableColumn!) ?? 0
        var cell = tableView.view(atColumn: column, row: row, makeIfNecessary: false) as? TorrentCellView
        if cell == nil {*/
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "torrentCellView"), owner: self) as? TorrentCellView else { return NSTableCellView()}
     /*       cell = theCell
        }*/
        let torrent = self.torrents[row]
        cell.update(withItem: torrent)
        cell.isSelected = tableView.isRowSelected(row)
        return cell
    }
    
/*    func tableViewSelectionDidChange(_ notification: Notification) {
        self.willChangeValue(forKey: #keyPath(selectionIndexes))
        let tableView = notification.object as! NSTableView
        self.selectionIndexes = tableView.selectedRowIndexes
        //self.torrentArrayController.setSelectionIndexes(proposedSelectionIndexes)
        self.didChangeValue(forKey: #keyPath(selectionIndexes))
    }
 */
    /// Drag and Drop
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: rowIndexes, requiringSecureCoding: false) else { return false}
        let item = NSPasteboardItem()
        item.setData(data, forType:.string)
        pboard.writeObjects([item])
        return true
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard let source = info.draggingSource as? NSTableView,
            source === torrentTableView
            else { return [] }
        if dropOperation == .above {
            return .move
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pb = info.draggingPasteboard
        if let itemData = pb.pasteboardItems!.first!.data(forType: .string),
            let indexes = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(itemData) as? IndexSet {
            let targetPos = self.torrents[row].queuePosition
            let field = [JSONKeys.queuePosition: targetPos]
            var trIds = indexes.map{ self.torrents[$0].trId }
            if row < indexes.first! {
                trIds.reverse()
            }
            self.session?.setFields(field, forTorrents: trIds, completionHandler: { error in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    }
                    else {
                        self.categorization.moveItems(from: indexes, to: row)
                        let targetIndex = row - (indexes.filter{ $0 < row }.count)
                        self.torrentArrayController.setSelectionIndexes(IndexSet(targetIndex..<targetIndex+indexes.count))
                    }
                }
            })
            return true
        }
        return false
    }
    
    
    /// Row Actions
    
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        var rowActions = [NSTableViewRowAction]()
        let completionHandler: (TrId,String)->Void =  { trId, message in
            InfoMessage.displayInfoMessage(message, in: self.view)
            self.session?.getInfo(forTorrents: [trId], withPriority: .veryHigh, andCompletionHandler: { (torrents, removed, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    } else {
                        if !(removed?.isEmpty ?? true){
                            self.categorization.removeItems(where: { removed!.contains($0.trId) })
                        }
                        self.categorization.updateItems(with: torrents!)
                    }
                }
            })
        }
        if edge == .leading {
            var rowAction = NSTableViewRowAction(style: .regular, title: "Start Now") { (rowAction, index) in
                let trId = self.torrents[index].trId
                self.session?.startNow(torrents: [trId], withPriority: .veryHigh, completionHandler: { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                        }
                        else {
                            if let cell = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? TorrentCellView {
                                cell.startStopButton.isEnabled = false
                            }
                            completionHandler(trId, "Torrent started successfully")
                        }
                    }
                })
            }
            rowAction.image = NSImage(named: "iconPlayNow")
            rowActions.append(rowAction)
            rowAction = NSTableViewRowAction(style: .regular, title: "Verify") { (rowAction, index) in
                let trId = self.torrents[index].trId
                self.session?.verify(torrents: [trId], withPriority: .veryHigh, completionHandler: { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                        }
                        else {
                            completionHandler(trId, "Torrent verifycation successful started")
                        }
                    }
                })
            }
            let image = NSImage(named: "NSMenuOnStateTemplate")
            image!.size = NSSize(width: 28, height: 28)
            rowAction.image = image
            rowAction.backgroundColor = .systemGreen
            rowActions.append(rowAction)
        } else {
            let rowActionR1 = NSTableViewRowAction(style: .destructive, title: "Delete") { (rowAction, index) in
                let trId = self.torrents[index].trId
                self.session?.remove(torrents: [trId], deletingLocalData: false, withPriority: .veryHigh, completionHandler: { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                        }
                        else {
                            InfoMessage.displayInfoMessage("Torrent successful deleted", in: self.view)
                        }
                    }
                })
            }
            rowActionR1.image = NSImage(named: "trash")
            rowActionR1.backgroundColor = .systemPink
            rowActions.append(rowActionR1)
            
            let rowActionR2 = NSTableViewRowAction(style: .destructive, title: "Delete with Files") { (rowAction, index) in
                let trId = self.torrents[index].trId
                self.session?.remove(torrents: [trId], deletingLocalData: true, withPriority: .veryHigh, completionHandler: { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                        }
                        else {
                            InfoMessage.displayInfoMessage("Torrent successful deleted", in: self.view)
                        }
                    }
                })
            }
            rowActionR2.image = NSImage(named: "trash.fill")
            rowActions.append(rowActionR2)
        }
        
        return rowActions
    }
}
