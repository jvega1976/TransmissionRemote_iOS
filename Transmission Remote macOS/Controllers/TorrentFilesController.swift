//
//  TorrentFilesController.swift
//  Transmission Remote
//
//  Created by  on 12/29/19.
//

import Cocoa
import Categorization
import TransmissionRPC

class TorrentFilesController: TorrentCommonController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {
    
    dynamic var categorization: TorrentCategorization {
        return TorrentCategorization.shared
    }
    
    dynamic var items: [Torrent] {
        return categorization.itemsForSelectedCategory as? [Torrent] ?? []
    }

    @IBOutlet weak var filesOutlineView: NSOutlineView!
    @IBOutlet var filesTreeController: NSTreeController!
    @IBOutlet var toolbarItem: NSToolbarItem!
    
    @objc dynamic var sortCriteria: [NSSortDescriptor]!
    @objc dynamic var selectedSortCriteria: Int = -1
    
    
    @objc dynamic var trId: TrId = 0 {
        didSet {
            if oldValue != trId {
                firstTime = true
                self.updateHandler(nil)
            }
        }
    }
    
    @objc dynamic var fsDir: FSDirectory? {
        willSet {
            self.willChangeValue(forKey: #keyPath(TorrentFilesController.files))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(TorrentFilesController.files))
        }
    }
    
    @objc dynamic var files: [FSItem] {
        return fsDir?.rootItem?.items ?? []
    }
    
    @objc dynamic var prevSelectedRows = IndexSet()
        
    var firstTime = true
    private var trIdContext = 0
    private var selectedRowsContext = 1
    private var isUpdating = false
    
    var session: RPCSession? {
        return RPCSession.shared
    }
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here
        self.updateHandler()
    }
    
    
    @objc func updateHandler(_ sender: Any? = nil) {
        if self.trId == 0 {
            self.trId = items[categorization.selectionIndexes.last ?? 0].trId
        }
        if firstTime {
            self.session?.getAllFiles(forTorrent: trId, withPriority: .veryHigh, completionHandler: { (fsDir, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.view)
                    } else {
                        self.fsDir = fsDir
                    }
                }
            })
            firstTime = false
        } else {
            self.session?.getAllFileStats(forTorrent: trId, withPriority: .veryHigh, completionHandler: { (fsStats, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.view)
                    } else {
                        if !self.isUpdating {
                            self.willChangeValue(forKey: #keyPath(files))
                        }
                        self.fsDir?.updateFSDir(usingStats: fsStats!)
                        if !self.isUpdating {
                            self.didChangeValue(forKey: #keyPath(files))
                        }
                    }
                }
            })
        }
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.trId = items[categorization.selectionIndexes.last ?? 0].trId
        self.updateHandler()
        // Do view setup here.
        categorization.addObserver(self, forKeyPath: #keyPath(TorrentCategorization.selectionIndexes), options: [.new], context: &trIdContext)
        self.timer = Timer.scheduledTimer(timeInterval: RPCServerConfig.sharedConfig?.refreshTimeout ?? 0, target: self, selector: #selector(updateHandler(_:)), userInfo: nil, repeats: true)
        filesTreeController.addObserver(self, forKeyPath: #keyPath(NSTreeController.selectedObjects), options: [.new], context: &selectedRowsContext)
        if !(NSApp.mainWindow?.toolbar?.visibleItems?.contains(where: {item in
            item.itemIdentifier == NSToolbarItem.Identifier("sortFiles")
        }) ?? true) {
            NSApp.mainWindow?.toolbar?.insertItem(withItemIdentifier: NSToolbarItem.Identifier.space, at: NSApp.mainWindow?.toolbar?.visibleItems?.count ?? 0)
            NSApp.mainWindow?.toolbar?.insertItem(withItemIdentifier: NSToolbarItem.Identifier(rawValue: "sortFiles"), at: NSApp.mainWindow?.toolbar?.visibleItems?.count ?? 0)
            NSApp.mainWindow?.toolbar?.insertItem(withItemIdentifier: NSToolbarItem.Identifier.space, at: NSApp.mainWindow?.toolbar?.visibleItems?.count ?? 0)
            NSApp.mainWindow?.toolbar?.insertItem(withItemIdentifier: NSToolbarItem.Identifier(rawValue: "searchFiles"), at: NSApp.mainWindow?.toolbar?.visibleItems?.count ?? 0)
        }
        
    }
    
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        categorization.removeObserver(self, forKeyPath: #keyPath(TorrentCategorization.selectionIndexes), context: &trIdContext)
         filesTreeController.removeObserver(self, forKeyPath: #keyPath(NSTreeController.selectedObjects), context: &selectedRowsContext)
        NSApp.mainWindow?.toolbar?.removeItem(at: NSApp.mainWindow!.toolbar!.visibleItems!.count - 1)
        NSApp.mainWindow?.toolbar?.removeItem(at: NSApp.mainWindow!.toolbar!.visibleItems!.count - 1)
        NSApp.mainWindow?.toolbar?.removeItem(at: NSApp.mainWindow!.toolbar!.visibleItems!.count - 1)
        NSApp.mainWindow?.toolbar?.removeItem(at: NSApp.mainWindow!.toolbar!.visibleItems!.count - 1)
        if self.timer.isValid {
            self.timer.invalidate()
        }
    }
    
    
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &trIdContext && object is TorrentCategorization {
            self.trId = items[categorization.selectionIndexes.last ?? 0].trId
        } else if context == &selectedRowsContext && object is NSTreeController {
            let selectedRows = filesOutlineView.selectedRowIndexes
            for i in self.prevSelectedRows.subtracting(selectedRows) {
                guard i < filesOutlineView.numberOfRows,
                    let cell = filesOutlineView.view(atColumn: 0, row: i, makeIfNecessary: false) as? TorrentFilesCell else { continue }
                cell.isSelected = false
            }
            for i in selectedRows.subtracting(self.prevSelectedRows) {
                guard i < filesOutlineView.numberOfRows,
                    let cell = filesOutlineView.view(atColumn: 0, row: i, makeIfNecessary: false) as? TorrentFilesCell else { continue }
                cell.isSelected = true
            }
            self.prevSelectedRows = selectedRows
        }
    }
    
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        self.isUpdating = true
    }
    
    @IBAction @objc func renameFile(_ sender: NSTextField) {
        guard let originalName = sender.dataObject as? String,
            !sender.stringValue.isEmpty else { return }
        let newName = sender.stringValue
        self.session?.renameFile(originalName, forTorrent: self.trId, usingName: newName, withPriority: .veryHigh, completionHandler: { error in
            DispatchQueue.main.async {
                if error != nil {
                    InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.view)
                }
                
                self.updateHandler()
            }
        })
        sender.dataObject = newName
        self.isUpdating = false
    }
    
    
    @IBAction @objc func toggleDownloading(_ sender: NSSwitch) {
        guard let item = sender.dataObject as? FSItem else { return }
        var rpcIdx =  [Int]()
        if filesTreeController.selectedObjects.contains(where: {($0 as! FSItem) == item}) {
            for object in filesTreeController.selectedObjects {
                guard let fsItem = object as? FSItem else {continue}
                rpcIdx.append(contentsOf: fsItem.rpcIndexes)
            }
        } else {
            rpcIdx = item.rpcIndexes
        }
        let wanted = sender.state == .on
        let rpcMessage = wanted ? [JSONKeys.files_wanted:rpcIdx] : [JSONKeys.files_unwanted:rpcIdx]
        session?.setFields(rpcMessage, forTorrents: [trId], withPriority: .veryHigh) { error in
            if error != nil {
                    DispatchQueue.main.async {
                        InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.view)
                    }
            } else {
                self.session?.getAllFileStats(forTorrent: self.trId, withPriority: .veryHigh, completionHandler: { (fsStats, error) in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.view)
                        } else {
                            self.fsDir?.updateFSDir(usingStats: fsStats!)
                        }
                    }
                })
            }
        }
    }
    
    
    
    @IBAction @objc func prioritySegmentToggled(_ sender: NSSegmentedControl) {
        guard let item = sender.dataObject as? FSItem else { return }
        var rpcIdx =  [Int]()
        if filesTreeController.selectedObjects.contains(where: {($0 as! FSItem) == item}) {
            for object in filesTreeController.selectedObjects {
                guard let fsItem = object as? FSItem else {continue}
                rpcIdx.append(contentsOf: fsItem.rpcIndexes)
            }
        } else {
            rpcIdx = item.rpcIndexes
        }
        let priority: FilePriority = FilePriority(rawValue: sender.selectedTag()) ?? .normal
        
        var rpcMessage = JSONObject()
        switch priority {
            case .low:
                rpcMessage[JSONKeys.priority_low] = rpcIdx
            case .normal:
                rpcMessage[JSONKeys.priority_normal] = rpcIdx
            case .high:
                rpcMessage[JSONKeys.priority_high] = rpcIdx
        }
        session?.setFields(rpcMessage, forTorrents: [trId], withPriority: .veryHigh) { error in
            if error != nil {
                DispatchQueue.main.async {
                    InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.view)
                }
            } else {
                self.session?.getAllFileStats(forTorrent: self.trId, withPriority: .veryHigh, completionHandler: { (fsStats, error) in
                    DispatchQueue.main.async {
                        if error != nil {
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.view)
                        } else {
                            self.fsDir?.updateFSDir(usingStats: fsStats!)
                        }
                    }
                })
            }
        }
        
    }
    
    
    @IBAction @objc func searchFiles(_ sender: NSButton) {
        
        guard let searchController = NSStoryboard.main?.instantiateController(withIdentifier: "FileSearchController") as? FileSearchController else { return }
        searchController.torrentFilesController = self
        self.present(searchController, asPopoverRelativeTo: NSRect(x: self.view.bounds.size.width - 10, y: self.view.bounds.size.height - 5, width: 10, height: 5), of: self.view, preferredEdge: .minY, behavior: .transient)
    }

    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TorrentFilesCell"), owner: self) as? TorrentFilesCell,
            let item = item as? NSTreeNode else { return NSTableCellView() }
        cell.isSelected = filesTreeController.selectedNodes.contains(item)
        cell.isWantedSwitch.dataObject = item.representedObject as? FSItem
        cell.prioritySegmentedControl.dataObject = item.representedObject as? FSItem
        if !self.isUpdating {
            cell.nameLabel.dataObject = (item.representedObject as? FSItem)?.name
        }
        return cell
    }
    
}
