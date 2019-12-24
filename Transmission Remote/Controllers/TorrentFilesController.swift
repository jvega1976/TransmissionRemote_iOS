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
        session = RPCSession.shared!
        super.viewDidLoad()
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
                    DispatchQueue.main.async {
                        displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                    }
                }
                else {
                    self.sessionConfig = sessionConfig
                }
            })
        }
        parent!.navigationItem.title = NSLocalizedString("Files", comment: "FileListController nav left button title")
        parent!.navigationItem.rightBarButtonItems = nil
        let searchButton = UIBarButtonItem(image: UIImage(systemName: "doc.text.magnifyingglass"), style: .plain, target: self, action: #selector(searchFiles(_:)))
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down.square"), style: .plain, target: self, action: #selector(sortFiles(_:)))
        parent!.navigationItem.rightBarButtonItems = [searchButton,sortButton]
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
                                var indexPaths = [IndexPath]()
                                for i in 0..<fileStats!.count {
                                    guard let fsitem = self.fsDir?.item(at: i) else { continue }
                                    indexPaths.append(fsitem.indexPath)
                                }
                                self.outlineView.reloadRows(at: indexPaths)
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
        guard let file = sender.dataObject as? FSItem else { return }

        let addAlert = UIAlertController(title: "Rename File", message: "Enter Filename: ", preferredStyle: .alert)
        addAlert.addTextField(configurationHandler: { textField in
                textField.frame.size = CGSize(width: 300, height: 16)
            textField.text = file.name
        })
        let actionAdd = UIAlertAction(title: "Rename", style: .default, handler: {_  in
            let name = addAlert.textFields!.first!.text!
            file.name = name
            self.session.renameFile(file.fullName, forTorrent:self.torrent.trId, usingName: name, withPriority: .veryHigh, completionHandler: { (error) in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                    } else {
                            self.isFullyLoaded = false
                            self.updateData()
                    }
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
            let item = cell.objectValue as? FSItem,
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
        var indexPaths: Array<IndexPath> = [item.indexPath]
        if addingTorrent {
            for i in fileIndexes {
                fsDir!.item(at: i)!.isWanted = wanted
                indexPaths.append(fsDir!.item(at: i)!.indexPath)
            }
            self.outlineView.reloadRows(at:indexPaths)
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
    
    
    @objc func searchFiles(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Search Files", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { textField in
            if UIDevice.current.userInterfaceIdiom == .pad {
                textField.frame.size = CGSize(width: 700, height: 16)
            } else {
                textField.frame.size = CGSize(width: 400, height: 16)
            }
        })
        let action = UIAlertAction(title: "Search", style: .default) { _ in
            var predicate: (FSItem)->Bool
            guard let searchText = alertController.textFields?.first?.text else { return }
            if searchText.count > 0 {
                let andWords = searchText.split(whereSeparator: { $0 == "&" })
                let orWords = searchText.split(whereSeparator: { $0 == "|" })
                predicate = {fsItem in
                    var result = true
                    if !andWords.isEmpty {
                        for word in andWords {
                            result = result && fsItem.name.localizedCaseInsensitiveContains(word.trimmingCharacters(in: .whitespaces))
                        }
                    }
                    if !orWords.isEmpty {
                        for word in orWords {
                            result = result || fsItem.name.localizedCaseInsensitiveContains(word.trimmingCharacters(in: .whitespaces))
                        }
                    }
                    if orWords.isEmpty && andWords.isEmpty {
                        result = result && fsItem.name.localizedCaseInsensitiveContains(searchText)
                    }
                    return result
                }
            } else {
                predicate = {fsItem in return true }
            }
            self.fsDir?.rootItem?.filterPredicate = predicate
            self.outlineView.reloadData()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(action)
        alertController.addAction(cancel)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func sortFiles(_ sender: UIBarButtonItem) {
        let alertActionDescendent = UIAlertAction(title: "Descending", style: .default, handler: {_ in
            let alertActionName = UIAlertAction(title: "Name", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    fileL.name > fileR.name
                }
                self.outlineView.reloadData()
            }
            
            let alertActionSize = UIAlertAction(title: "Size", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    fileL.size > fileR.size
                }
                self.outlineView.reloadData()
            }
            
            let alertActionProgress = UIAlertAction(title: "Percentage Progress", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    fileL.downloadProgress > fileR.downloadProgress
                }
                self.outlineView.reloadData()
            }
            
            let alertActionWanted = UIAlertAction(title: "Selected for Download", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    (fileL.isWanted ? 1 : 0) > (fileR.isWanted ? 1 : 0)
                }
                self.outlineView.reloadData()
            }
            
            let alertController = UIAlertController(title: "Sort Options", message: nil, preferredStyle: .actionSheet)
            alertController.addAction(alertActionName)
            alertController.addAction(alertActionSize)
            alertController.addAction(alertActionProgress)
            alertController.addAction(alertActionWanted)
            if UIDevice.current.userInterfaceIdiom == .pad {
                guard let popoverController = alertController.popoverPresentationController else {
                    return
                }
                popoverController.barButtonItem = sender
            }
            self.present(alertController, animated: true, completion: nil)
        })
        
        let alertActionAscendent = UIAlertAction(title: "Ascending", style: .default, handler: {_ in
            let alertActionName = UIAlertAction(title: "Name", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    fileL.name < fileR.name
                }
                self.outlineView.reloadData()
            }
            
            let alertActionSize = UIAlertAction(title: "Size", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    fileL.size < fileR.size
                }
                self.outlineView.reloadData()
            }
            
            let alertActionProgress = UIAlertAction(title: "Percentage Progress", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    fileL.downloadProgress < fileR.downloadProgress
                }
                self.outlineView.reloadData()
            }
            
            let alertActionWanted = UIAlertAction(title: "Selected for Download", style: .default) { _ in
                self.fsDir?.sortPredicate = { fileL, fileR in
                    (fileL.isWanted ? 1 : 0) < (fileR.isWanted ? 1 : 0)
                }
                self.outlineView.reloadData()
            }
            
            let alertController = UIAlertController(title: "Sort Options", message: nil, preferredStyle: .actionSheet)
            alertController.addAction(alertActionName)
            alertController.addAction(alertActionSize)
            alertController.addAction(alertActionProgress)
            alertController.addAction(alertActionWanted)
            if UIDevice.current.userInterfaceIdiom == .pad {
                guard let popoverController = alertController.popoverPresentationController else {
                    return
                }
                popoverController.barButtonItem = sender
            }
            self.present(alertController, animated: true, completion: nil)
        })
        let alertController = UIAlertController(title: "Order Options", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(alertActionDescendent)
        alertController.addAction(alertActionAscendent)
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let popoverController = alertController.popoverPresentationController else {
                return
            }
            popoverController.barButtonItem = sender
        }
        self.present(alertController, animated: true, completion: nil)
    }

}


//MARK: - NMOutlineViewDatasource extension
extension TorrentFilesController {
    
    override func outlineView(_ outlineView: NMOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? FSItem else { return fsDir?.rootItem!.items?.count ?? 0}
        return item.items?.count ?? 0
    }
    
    override func outlineView(_ outlineView: NMOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? FSItem else { return false }
        return item.isFolder
    }
    
    
    override func outlineView(_ outlineView: NMOutlineView, cellFor item: Any) -> NMOutlineViewCell  {
        guard let item = item as? FSItem else { return NMOutlineViewCell() }
        let cell = outlineView.dequeReusableCell(withIdentifier: CELL_ID_FILELISTFSCELL, style: .default) as! FileListFSCell
        cell.torrentFilesController = self
        cell.update(with: item)
        return cell
    }

    
    override func outlineView(_ outlineView: NMOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item as? FSItem else { return fsDir?.rootItem!.items?[index] }
        return item.items?[index]
    }
    
}
