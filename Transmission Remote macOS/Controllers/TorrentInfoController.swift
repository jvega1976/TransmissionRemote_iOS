//
//  TorrentInfoController.swift
//  Transmission Remote
//
//  Created by  on 12/13/19.
//

import Cocoa
import TransmissionRPC
import Categorization

@objcMembers public class TorrentInfoController: TorrentCommonController {
    
    var isEditing = false
    var oldValue: String?
    
    
    @IBOutlet @objc dynamic var torrentArrayController: NSArrayController!
    
    dynamic var categorization: TorrentCategorization {
        return TorrentCategorization.shared
    }
    
    @objc dynamic var items: Array<Torrent> {
        return categorization.itemsForSelectedCategory as! Array<Torrent>
    }
    
    @objc dynamic var selectedIndexes: IndexSet {
        get {
            return self.categorization.selectionIndexes
        }
        set {
            return
        }
    }    
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
    override public func viewWillAppear() {
        super.viewWillAppear()
        self.willChangeValue(forKey: #keyPath(selectedIndexes))
        self.didChangeValue(forKey: #keyPath(selectedIndexes))
        categorization.addObserver(self, forKeyPath: #keyPath(TorrentCategorization.itemsForSelectedCategory), options: [.prior, .new], context: &observeContext)
        categorization.addObserver(self, forKeyPath: #keyPath(TorrentCategorization.selectionIndexes), options: [.prior, .new], context: &indexesContext)
    }
    
    
    override public func viewWillDisappear() {
        super.viewWillDisappear()
        categorization.removeObserver(self, forKeyPath: #keyPath(TorrentCategorization.itemsForSelectedCategory), context: &observeContext)
        categorization.removeObserver(self, forKeyPath: #keyPath(TorrentCategorization.selectionIndexes), context: &indexesContext)
    }
    
    
    @IBAction @objc func updateTorrent( _ sender: NSResponder) {
        var binding: [NSBindingInfoKey : Any]?
        if sender is NSSegmentedControl {
            binding = (sender as! NSSegmentedControl).infoForBinding(.selectedTag)
        } else {
            guard let sender = sender as? NSControl else { return }
            binding = sender.infoForBinding(.value)
        }
        var field: JSONObject
        guard let keyPath = (binding?[NSBindingInfoKey.observedKeyPath] as? String)?.replacingOccurrences(of: "selection.", with: "") else { return }
        guard let keyPathName = Torrent.propertyStringName(stringValue: keyPath) else { return }
        if sender is NSSegmentedControl {
            field = [keyPathName: (sender as! NSSegmentedControl).selectedTag()]
            
        } else  {
            guard let sender = sender as? NSControl else { return }
            field = [keyPathName: sender.value(forKey: "integerValue")!]
        }
 
        let torrents = torrentArrayController.selectedObjects as! [Torrent]
        
        let trIds = torrents.compactMap { (torrent) -> TrId in
            return torrent.trId
        }
        RPCSession.shared?.setFields(field, forTorrents: trIds, withPriority: .veryHigh, completionHandler: { error in
            if error != nil {
                DispatchQueue.main.async {
                    InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.parent!.view)
                }
            } else {
                RPCSession.shared?.getInfo(forTorrents: RecentlyActive, withPriority: .veryHigh, andCompletionHandler: { torrents,removed,error in
                     DispatchQueue.main.async {
                        if error != nil {
                            
                            InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.parent!.view)
                        }
                        else {
                            if !(removed?.isEmpty ?? true)  {
                                self.categorization.removeItems(where: {removed!.contains($0.trId)})
                            }
                            TorrentCategorization.shared.updateItems(with: torrents!)
                        }
                    }
                })
            }
        })
    }
    
    
    private var observeContext = 0
    private var indexesContext = 1
    
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &observeContext && object is TorrentCategorization
        {
            if let kindKey = NSKeyValueChange(rawValue: (change?[NSKeyValueChangeKey.kindKey] as? UInt ?? 0)),
                [NSKeyValueChange.insertion, NSKeyValueChange.removal, NSKeyValueChange.replacement].contains(kindKey),
                let indexSet = change?[NSKeyValueChangeKey.indexesKey] as? NSIndexSet
            {
                if change?[NSKeyValueChangeKey.notificationIsPriorKey] as? Bool ?? false
                {
                    self.willChange(kindKey, valuesAt: indexSet as IndexSet, forKey: #keyPath(TorrentInfoController.items))
                } else
                {
                    self.didChange(kindKey, valuesAt: indexSet as IndexSet, forKey: #keyPath(TorrentInfoController.items))
                }
            } else if let kindKey = NSKeyValueChange(rawValue: (change?[NSKeyValueChangeKey.kindKey] as? UInt ?? 0)),
                kindKey == .setting {
                if change?[NSKeyValueChangeKey.notificationIsPriorKey] as? Bool ?? false
                {
                    self.willChangeValue(forKey: #keyPath(TorrentInfoController.items))
                } else
                {
                    self.didChangeValue(forKey: #keyPath(TorrentInfoController.items))
                }
                
            }
        }
        else if context == &indexesContext && object is TorrentCategorization {
            if change?[NSKeyValueChangeKey.notificationIsPriorKey] as? Bool ?? false
            {
                self.willChangeValue(forKey: #keyPath(TorrentInfoController.selectedIndexes))
            } else
            {
                self.didChangeValue(forKey: #keyPath(TorrentInfoController.selectedIndexes))
            }
        }
    }
    
    @IBAction func renameTorrent(_ sender: NSTextField) {
        let newName = sender.stringValue
        guard let torrent = torrentArrayController.selectedObjects.first as? Torrent,
            let oldName = torrent.name else { return }
        let trId = torrent.trId
        RPCSession.shared?.renameFile(oldName, forTorrent: trId, usingName: newName, completionHandler: { error in
            if error != nil {
                InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.parent!.view)
                sender.stringValue = oldName
            }
        })
    }
    
    @IBAction func setLocation(_ sender: NSTextField) {
        let location = sender.stringValue
        guard let torrent = torrentArrayController.selectedObjects.first as? Torrent,
            let oldLocation = oldValue else { return }
        let trId = torrent.trId
        RPCSession.shared?.setLocation(forTorrent: trId, location: location, completionHandler: { error in
            if error != nil {
                InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.parent!.parent!.parent!.view)
                sender.stringValue = oldLocation
            }
        })
    }
    
}


extension TorrentInfoController: NSTextFieldDelegate {
    
    public func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        return !isEditing
    }
    
    public func controlTextDidBeginEditing(_ obj: Notification) {
        isEditing = true
        guard let field = obj.object as? NSTextField else { return }
        oldValue = field.stringValue
    }
    
    public func controlTextDidEndEditing(_ obj: Notification) {
        isEditing = false
    }
}
