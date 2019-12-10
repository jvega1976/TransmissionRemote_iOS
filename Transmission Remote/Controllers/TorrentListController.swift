    //
    //  TorrentListController.swift
    //  Transmission Remote
    //
    //  Created by  on 7/14/19.
    //

    import UIKit
    import MobileCoreServices
    import TransmissionRPC
    import Categorization

    @objcMembers
    public class TorrentListController: UIViewController,
        UISearchBarDelegate,
        UIPopoverPresentationControllerDelegate
    {
        
        
        @IBOutlet weak var toolbar: UIToolbar!
        @IBOutlet weak var toolbarEdit: UIToolbar!
        
        
        @IBOutlet weak var searchBar: UISearchBar!
        @IBOutlet weak var searchView: UIView!
        
        @IBOutlet var mainView: UIView!
        
        @IBOutlet var rightBarButtons: [UIBarButtonItem]?
        
        @IBOutlet var containerView: UIView!
        
        var chooseNav: UINavigationController!
        var torrentFile: TorrentFile!
        var magnetURL: MagnetURL!
        
        var session: RPCSession!
        
        var categorization: TorrentCategorization!
        private var categoryIndex: Int! = -1
        private var category: TorrentCategory!
        var viewVisualEffect: UIVisualEffectView!
        
        let defaults = UserDefaults.standard
        
        var torrentTableController: TorrentTableController!
        
        func fillNavigationBar() {
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.hidesBackButton = false
            
        }
        
        
        override public func viewDidLoad() {
            super.viewDidLoad()
            categorization = TorrentCategorization.shared
            if categoryIndex == -1 {
                categoryIndex = TR_CAT_IDX_ALL
            }
            categorization.visibleCategoryPredicate = { category in self.categorization.numberOfItemsInCategory(atPosition: self.categoryIndex) > 0 }
            fillNavigationBar()
            searchView.isHidden = true
        }
        
        
        // MARK: - UISearchBarDelegate
        
        public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            var predicate: TorrentPredicate
            if searchBar.text?.count ?? 0 > 0 {
                predicate = {element in element.name.localizedCaseInsensitiveContains(self.searchBar.text!)}
            } else {
                predicate = {element in return true }
            }
            torrentTableController.categorization.filterPredicate = predicate
            torrentTableController.torrents = torrentTableController.categorization.itemsforCategory(atPosition: categoryIndex).sorted(by: >)
            torrentTableController.torrentsCount.text = torrentTableController.torrents.count != 0 ?  String(torrentTableController.torrents.count) : ""
            searchBar.endEditing(true)
            torrentTableController.tableView.reloadData()
        }
        
        
        // MARK: - Interface Actions
                
        @objc @IBAction func search(_ sender: UIBarButtonItem) {
            searchBar.isHidden = !searchBar.isHidden
            searchView.frame.size.height = 56.0
            if searchBar.isHidden {
                containerView.frame.origin.y = containerView.frame.origin.y - 56.0
            }
            else {
                containerView.frame.origin.y = searchView.frame.origin.y + 56.0
            }
            searchView.isHidden = searchBar.isHidden
            mainView.setNeedsDisplay()
        }
        

        @objc @IBAction func editTorrents(_ sender: UIBarButtonItem) {
            torrentTableController.tableView.setEditing(true, animated: true)
            self.rightBarButtons = navigationItem.rightBarButtonItems
            navigationItem.rightBarButtonItems = nil
            navigationItem.hidesBackButton = true
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: torrentTableController, action: #selector(torrentTableController.cancelEditing))
            let selectAllButton = UIBarButtonItem(title: "Select All", style: .plain, target: torrentTableController, action: #selector(torrentTableController.selectAllRows(_:)))
            navigationItem.rightBarButtonItem = selectAllButton
            navigationItem.leftBarButtonItem = cancelButton
            
            toolbar.isHidden = true
            toolbarEdit.isHidden = false
        }
        
        
        @IBAction @objc func startAllTorrents(_ sender:UIBarButtonItem) {
            torrentTableController.startAllTorrents(sender)
        }
        
        @IBAction @objc func stopAllTorrentsAction(_ sender:UIBarButtonItem) {
            torrentTableController.stopAllTorrentsAction(sender)
        }
        
        
        @IBAction @objc func pauseTorrents(_ sender:UIBarButtonItem) {
            torrentTableController.pauseTorrents(sender)
        }
        
        
        @IBAction @objc func resumeTorrents(_ sender: UIBarButtonItem) {
            torrentTableController.resumeTorrents(sender)
        }
        
        
        @IBAction @objc func resumeNowTorrents(_ sender: UIBarButtonItem) {
            torrentTableController.resumeNowTorrents(sender)
        }
        
        
        @IBAction @objc func removeTorrents(_ sender:UIBarButtonItem) {
            torrentTableController.removeTorrents(sender)
        }
        
        
        @IBAction @objc func verifyTorrents(_ sender: UIBarButtonItem) {
            torrentTableController.verifyTorrents(sender)
        }
        
        
        @IBAction @objc func reannounceTorrents(_ sender: UIBarButtonItem) {
            torrentTableController.reannounceTorrents(sender)
        }
        
        
        // MARK: - Segues
        
        override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "torrentTableController" {
                torrentTableController = (segue.destination as! TorrentTableController)
                torrentTableController.categorization = categorization
                torrentTableController.categoryIndex = categoryIndex
                torrentTableController.category = category
                
            } else if segue.identifier == "filterTorrents" {
                let popoverViewController = segue.destination as! TorrentFilterController
                popoverViewController.torrentTableController = torrentTableController
                popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
                popoverViewController.popoverPresentationController!.delegate = self
                torrentTableController.addBlurEffect(style: .systemThinMaterial)
            } else if segue.identifier == "sortTorrents" {
                let popoverViewController = segue.destination as! TorrentSortController
                popoverViewController.torrentTableController = torrentTableController
                popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
                popoverViewController.popoverPresentationController!.delegate = self
                torrentTableController.addBlurEffect(style: .systemThinMaterial)
            } else if segue.identifier == "sessionStats" {
                let popoverViewController = segue.destination as! SessionStatsController
                popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
                popoverViewController.popoverPresentationController!.delegate = self
                torrentTableController.addBlurEffect(style: .systemMaterialDark)
            }
            
            
        }
        
        public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
            // Tells iOS that we do NOT want to adapt the presentation style for iPhone
            return .none
        }
        
        
        public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
            torrentTableController.removeBlurEffect()
        }
    }
    
    


    // MARK: - Add Torrent Extension
    extension TorrentListController: UIDocumentPickerDelegate {
       
        
        @IBAction @objc func addTorrent(_ sender: UIBarButtonItem) {
            let picker = UIDocumentPickerViewController(documentTypes: ["com.alcheck.TransmissionRPCClient.torrent"], in: .open)
            picker.delegate = self
            self.present(picker, animated: true)
        }
        
        func addTorrentToServer(withRPCConfig config: RPCServerConfig, priority: Int, startNow: Bool) {
            var session:RPCSession!
            if RPCSession.shared?.url != config.configURL {
                do {
                session = try RPCSession(withURL: config.configURL!, andTimeout: config.requestTimeout)
                } catch {
                    displayErrorMessage(error.localizedDescription, using: self.torrentTableController)
                    return
                }
            }
            else {
                session = RPCSession.shared!
            }
            
            if torrentFile != nil {
                session.addTorrent(usingFile: torrentFile, addPaused: false, withPriority: .veryHigh) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            displayErrorMessage(error!.localizedDescription, using: self.torrentTableController)
                        } else {
                            self.torrentTableController.updateData()
                            displayInfoMessage(NSLocalizedString("New torrent has been added", comment: ""), using: self.torrentTableController)
                        }
                    }
                }
            } else if magnetURL != nil {
               
            }
        }
        
        
        @objc func addTorrentToSelectedServer() {
            let csc = chooseNav.viewControllers[0] as! AddFileController
     
            if csc.files != nil {
                torrentFile.fs = csc.files
            }
            addTorrentToServer(withRPCConfig: csc.rpcConfig!, priority: csc.bandwidthPriority - 1, startNow: csc.startImmidiately)
            dismissChooseServerController()
        }
    
        @objc func dismissChooseServerController() {
            torrentTableController.removeBlurEffect()
            chooseNav.dismiss(animated: true)
            chooseNav = nil
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                if chooseNav != nil {
                    chooseNav.dismiss(animated: false)
                }
                
                torrentFile = nil
                magnetURL = nil
                
                if MagnetURL.isMagnetURL(url) {
                    magnetURL = MagnetURL(url: url)
                } else {
                    if url.startAccessingSecurityScopedResource() {
                        torrentFile = TorrentFile(fileURL: url)
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                if ServerConfigDB.shared.db.count > 0 && ((torrentFile != nil) || magnetURL != nil) {
                    // presenting view controller to choose from several remote servers
                    let chooseServerController = instantiateController(CONTROLLER_ID_CHOOSESERVER) as! AddFileController

                    chooseServerController.isMagnet = magnetURL != nil
                    
                    if magnetURL != nil {
                        chooseServerController.setTorrentTitle(magnetURL.name, andTorrentSize: magnetURL.torrentSizeString)
                        chooseServerController.announceList = magnetURL.trackerList
                    } else {
                        chooseServerController.setTorrentTitle(torrentFile.name, andTorrentSize: torrentFile.torrentSizeString)
                        
                        chooseServerController.files = torrentFile.fileList
                        chooseServerController.announceList = torrentFile.trackerList
                    }
                    
                    let leftButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(dismissChooseServerController))
                    
                    let rightButton = UIBarButtonItem(title: NSLocalizedString("OK", comment: ""), style: .plain, target: self, action: #selector(addTorrentToSelectedServer))
                    
                    chooseServerController.navigationItem.leftBarButtonItem = leftButton
                    chooseServerController.navigationItem.rightBarButtonItem = rightButton
                    
                    
                    chooseNav = UINavigationController(rootViewController: chooseServerController)
                    chooseNav.modalPresentationStyle = .formSheet
                    torrentTableController.addBlurEffect(style: .regular)
                    self.present(chooseNav, animated: true)
                } else {
                    let alert = UIAlertController(title: NSLocalizedString("There are no servers avalable", comment: ""), message: NSLocalizedString("Add server to the list and try again", comment: ""), preferredStyle: .alert)
                    let okAlertAction = UIAlertAction(title: "OK", style: .cancel, handler: {_ in })
                    alert.addAction(okAlertAction)
                    chooseNav.present(alert, animated: true, completion: nil)
                }
            }
        }
        
    }
