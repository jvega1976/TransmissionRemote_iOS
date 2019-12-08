//
//  TorrentFilesController.swift
//  Transmission Remote
//
//  Created by  on 7/16/19.
//

import UIKit
import TransmissionRPC
import AVFoundation
import AVKit
import NMOutlineView

let ICON_FILE = "iconFile"
let ICON_FOLDER_OPENED = "iconFolderOpened"
let ICON_FOLDER_CLOSED = "iconFolderClosed"

let CONTROLLER_ID_FILELIST = "fileListController"


class TorrentFilesController: NMOutlineViewController, RefreshTimer {
    
    
//    @IBOutlet var outlineView: NMOutlineView!
    var _fsDir: FSDirectory?
    /// Flag indicates if this torrent if fully loaded and not needed be updated more
    private(set) var isFullyLoaded = false
    var selectOnly = false
    public var addingTorrent = false
    public var session:RPCSession!
    public var torrent:Torrent!
    private var firstTime: Bool = true
    private var sessionConfig: SessionConfig?
    
    var fsDir: FSDirectory? {
        set(newFsDir) {
            if _fsDir == nil {
                _fsDir = newFsDir
                if outlineView == nil {
                    self.loadView()
                }
                //                outlineView.tableView = self.tableView
                outlineView.datasource = self
            } else {
                _fsDir = newFsDir
            }
            isFullyLoaded = _fsDir!.rootItem?.downloadProgress ?? 0.0 >= 1.0
        }
        get {
            return _fsDir
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session = RPCSession.shared!
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !addingTorrent {
            self.startTimer()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(startTimer(_:)),
                                                   name: .EnableTimers, object: nil)
            session.getSessionConfig(withPriority: .veryHigh, andCompletionHandler: { sessionConfig, error in
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                }
                else {
                    self.sessionConfig = sessionConfig
                }
            })
        }
        parent!.navigationItem.title = NSLocalizedString("Files", comment: "FileListController nav left button title")
        parent!.navigationItem.rightBarButtonItems = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !addingTorrent {
            
            stopRefresh() //Method inherited from RefreshTimer Protocol
            NotificationCenter.default.removeObserver(self, name:  .EnableTimers, object: nil)
        }
        else {
            (navigationController!.viewControllers.last as! AddFileController).files = fsDir
        }
        navigationController?.isToolbarHidden = true
    }
    
    
    @objc func startTimer(_ notification: Notification? = nil) {
        if  notification != nil {
            try? RPCSession.shared?.restart()
        }
        firstTime = true
        startRefresh() //Method inherited from RefreshTimer Protocol
    }
    
     @objc func updateData(_ sender: Any? = nil) {
        if !isFullyLoaded {
            if firstTime {
                self.session.getAllFiles(forTorrent: torrent.trId) { (directory, error) in
                    DispatchQueue.main.async {
                        if error == nil {
                            self.fsDir = directory
                            self.outlineView.reloadData()
                        }
                        else {
                            displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                        }
                    }
                }
                firstTime = false
            }
            else {
                DispatchQueue.global().async {
                    self.session.getAllFileStats(forTorrent: self.torrent.trId) { (fileStats, error) in
                        DispatchQueue.main.async {
                            if error == nil {
                                self.fsDir!.updateFSDir(usingStats: fileStats!)
                                self.outlineView.reloadData()
                            }
                            else {
                                displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - File Actions
    
    @objc func toggleDownloadAllItems() {
        
        guard let item = fsDir?.rootItem else {return}
        
        let wanted = !item.isWanted
        item.isWanted = wanted
        
        if !addingTorrent {
            if wanted {
                let fileIndexes = item.rpcIndexes
                let rpcMessage = [JSONKeys.files_wanted: fileIndexes]
                session.setFields(rpcMessage, forTorrents: [torrent.trId]) { error in
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.view.window?.rootViewController)
                    } else {
                        self.updateData()
                    }
                }
            } else {
                let fileIndexes = item.rpcIndexes
                let rpcMessage = [JSONKeys.files_unwanted: fileIndexes]
                session.setFields(rpcMessage, forTorrents: [torrent.trId]) { error in
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.view.window?.rootViewController)
                    } else {
                        self.updateData()
                    }
                }
            }
        }
        
        outlineView.reloadData()
    }
    

    
    @objc func renameFile(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: outlineView)
        guard let cell = outlineView.cellAtPoint(point) as? FileListFSCell,
            let indexPath = outlineView.indexPathforCell(at: point),
            let file = cell.value as? FSItem else { return}
            let addAlert = UIAlertController(title: "Rename File", message: "Enter Filename: ", preferredStyle: .alert)
        addAlert.addTextField(configurationHandler: { textField in
                textField.frame.size = CGSize(width: 300, height: 16)
                textField.text = cell.nameLabel.text
        })
        let actionAdd = UIAlertAction(title: "Rename", style: .default, handler: {_  in
            let name = addAlert.textFields!.first!.text!
            self.fsDir!.item(atIndexPath: indexPath)!.name = name
            self.session.renameFile(file.fullName, forTorrent:self.torrent.trId, usingName: name, withPriority: .veryHigh, completionHandler: { (error) in
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                } else {
                        self.isFullyLoaded = false
                        self.updateData()
                }
            })
        })
        addAlert.addAction(actionAdd)
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        addAlert.addAction(actionCancel)
        self.present(addAlert, animated: true, completion: nil)
        
    }
    
    
    
    @IBAction @objc func playFile(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: outlineView)
        guard let cell = outlineView.cellAtPoint(point) as? FileListFSCell,
            let item = cell.value as? FSItem,
            let webDAVServer = UserDefaults.standard.string(forKey: USERDEFAULTS_KEY_WEBDAV),
            let fileURL = item.fullName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }
        
        var url: URL?
        if sessionConfig?.incompletedDirEnabled ?? false {
            url = URL(string: webDAVServer + (sessionConfig?.incompletedDir == nil ? "/" : "../" ) + ((sessionConfig?.incompletedDir as NSString?)?.lastPathComponent ?? "") + fileURL)
        } else {
            url = URL(string: webDAVServer + "/" + fileURL)
        }
        if url != nil {
            let player = AVPlayer(url: url!)
        
        // Create a new AVPlayerViewController and pass it a reference to the player.
            let controller = AVPlayerViewController()
            controller.player = player
            
            // Modally present the player and call the player's play() method when complete.
            present(controller, animated: true) {
                player.play()
            }
        }
    }
    
    
    @objc func toggleDownloading(_ sender: UICheckBox?) {
        let item = sender?.dataObject as! FSItem
        let fileIndexes = item.rpcIndexes
        let wanted = !item.isWanted
        if addingTorrent {
            for i in fileIndexes {
                fsDir!.item(at: i)!.isWanted = wanted
            }
            self.outlineView.reloadData()
            return
        }
        let rpcMessage = wanted ? [JSONKeys.files_wanted:fileIndexes] : [JSONKeys.files_unwanted:fileIndexes]
        session.setFields(rpcMessage, forTorrents: [torrent.trId], withPriority: .veryHigh) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.view.window?.rootViewController)
                } else {
                    self.updateData()
                }
            }
            
        }
    }
    
    
    
    @objc func prioritySegmentToggled(_ sender: UISegmentedControl) {
        guard let priority: FilePriority = FilePriority(rawValue: sender.selectedSegmentIndex),
            let item = sender.dataObject as? FSItem else {return}
        item.priority = priority
        
        if addingTorrent {
            if item.isFile {
                fsDir!.item(atIndexPath: item.indexPath)!.priority = priority
                
            } else {
                for i in fsDir!.item(atIndexPath: item.indexPath)!.items! {
                    fsDir!.item(atIndexPath: i.indexPath)!.priority = priority
                }
            }
            return
        }
        
        let rpcIdx = item.rpcIndexes
        var rpcMessage = JSONObject()
        switch priority {
            case .low:
                rpcMessage[JSONKeys.priority_low] = rpcIdx
            case .normal:
                rpcMessage[JSONKeys.priority_normal] = rpcIdx
            case .high:
                rpcMessage[JSONKeys.priority_high] = rpcIdx
        }
        
        session.setFields(rpcMessage, forTorrents: [torrent.trId], withPriority: .veryHigh) { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.view.window?.rootViewController)
                } else {
                    self.updateData()
                }
            }
        }
    }
    
    
    //MARK: - Update Interface methods
    
    func updateFileCell(_ cell: FileListFSCell, with item: FSItem) {
        cell.nameLabel.text = item.name
        // remove all old targets
        cell.checkBox.removeTarget(self, action: #selector(toggleDownloading(_:)), for: .valueChanged)
        cell.checkBox.removeTarget(self, action: #selector(toggleDownloading(_:)), for: .valueChanged)
        cell.fileTypeIcon.image = UIImage(systemName: "doc")
        
        cell.value = item
        if addingTorrent {
            cell.progressBar.isHidden = true
            cell.detailLabel.isHidden = true
        } else {
            cell.progressBar.progress = Float(item.downloadProgress)
            cell.detailLabel.text = NSLocalizedString("\(item.bytesCompletedString) of \(item.sizeString), \(item.downloadProgressString) downloaded", comment: "FileList cell file info")
        }
        cell.prioritySegment.isHidden = false // by default folders don't have priority segment
        cell.nameLabel.textColor = UIColor.label // by default file/folder names are black
        if cell.longPressView.gestureRecognizers == nil {
            cell.longPressView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(renameFile(_:))))
        }
        cell.longPressView.isUserInteractionEnabled = true
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(playFile(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        cell.contentView.addGestureRecognizer(doubleTapRecognizer)
        cell.contentView.isUserInteractionEnabled = true
        
        cell.prioritySegment.addTarget(self, action: #selector(prioritySegmentToggled(_:)), for: .valueChanged)
        cell.prioritySegment.dataObject = item
        cell.prioritySegment.selectedSegmentIndex = item.priority.rawValue
        cell.checkBox.dataObject = item
        
        // configure left checkBox control
        cell.checkBox.addTarget(self, action: #selector(toggleDownloading(_:)), for: .valueChanged)
        
        if item.isWanted {
            cell.prioritySegment.isEnabled = true
        }else {
            cell.prioritySegment.isEnabled = false
        }
        
        cell.checkBox.isSelected = item.isWanted
        cell.checkBox.tintColor = item.isWanted ? cell.tintColor : UIColor.secondaryLabel
    }
    
    func updateFolderCell(_ cell: FileListFSCell, with item: FSItem) {
        // remove all old targets
        cell.nameLabel.text = item.name
        cell.checkBox.removeTarget(self, action: #selector(toggleDownloading(_:)), for: .valueChanged)
        cell.checkBox.removeTarget(self, action: #selector(toggleDownloading(_:)), for: .valueChanged)
        
        cell.value = item
        cell.fileTypeIcon.image = UIImage(systemName: "folder.fill")
        if addingTorrent {
            cell.progressBar.isHidden = true
            cell.detailLabel.text = String(format: NSLocalizedString("%i files, %@", comment: ""), item.filesCount, item.sizeString)
        }
        else {
            cell.progressBar.progress = Float(item.downloadProgress)
            cell.detailLabel.text = String(format: NSLocalizedString("%i files, %@ of %@, %@ downloaded", comment: ""), item.filesCount, item.bytesCompletedString, item.sizeString, item.downloadProgressString)
        }
        cell.prioritySegment.addTarget(self, action: #selector(prioritySegmentToggled(_:)), for: .valueChanged)
        cell.prioritySegment.dataObject = item
        cell.prioritySegment.isEnabled = true
        cell.prioritySegment.selectedSegmentIndex = item.priority.rawValue
        cell.nameLabel.textColor = UIColor.label // by default file/folder names are black
        
        if cell.longPressView.gestureRecognizers == nil {
            cell.longPressView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(renameFile(_:))))
        }
        cell.longPressView.isUserInteractionEnabled = true
        
        // get info for files within folder
        
        cell.checkBox.isSelected = item.isWanted
        
        cell.checkBox.tintColor = item.isWanted ? cell.tintColor : UIColor.secondaryLabel
        
        // add recognizer for unwanted files
        cell.checkBox.dataObject = item
        cell.checkBox.addTarget(self, action: #selector(toggleDownloading(_:)), for: .valueChanged)
        cell.toggleButton.contentHorizontalAlignment = .right
        // Add tap handeler for folder - open/close
        //cell.longPressView.layoutIfNeeded()
    }
}


//MARK: - NMOutlineViewDatasource extension
extension TorrentFilesController {
    
    override func outlineView(_ outlineView: NMOutlineView, numberOfChildrenOfCell parentCell: NMOutlineViewCell?) -> Int {
        guard let datasource = fsDir?.rootItem!.items else {
            return 0
        }
        if let parentNode = parentCell?.value as? FSItem {
            return parentNode.items?.count ?? 0
        } else {
            // Top level items
            return datasource.count
        }
        
    }
    
    override func outlineView(_ outlineView: NMOutlineView, isCellExpandable cell: NMOutlineViewCell) -> Bool {
        guard let node = cell.value as? FSItem else {
            return false
        }
        return node.isFolder
    }
    
    
    override func outlineView(_ outlineView: NMOutlineView, childCell index: Int, ofParentAtIndexPath parentIndexPath: IndexPath?) -> NMOutlineViewCell {
        
        if let parentIndexPath = parentIndexPath //, let rootIndex = parentIndexPath.first
        {
            let cell = outlineView.dequeReusableCell(withIdentifier: CELL_ID_FILELISTFSCELL, style: .default) as! FileListFSCell
            let indexPath = parentIndexPath.appending(index)
            if let item = fsDir!.item(atIndexPath: indexPath) {
                if item.isFolder {
                    updateFolderCell(cell, with: item)
                } else {
                    updateFileCell(cell, with: item)
                }
                
            }
            return cell
        } else {
            let cell = outlineView.dequeReusableCell(withIdentifier: CELL_ID_FILELISTFSCELL, style: .default) as! FileListFSCell
            
            if let item = fsDir?.rootItem?.items?[index] {
                if item.isFolder {
                    updateFolderCell(cell, with: item)
                } else {
                    updateFileCell(cell, with: item)
                }
            }
            return cell
        }
    }
    
    
    override func outlineView(_ outlineView: NMOutlineView, didSelectCell cell: NMOutlineViewCell) {
        
    }
    
}
