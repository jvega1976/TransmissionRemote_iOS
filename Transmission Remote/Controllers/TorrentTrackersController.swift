//
//  TorrentTrackersController.swift
//  Transmission Remote
//
//  Created by  on 7/16/19.
//

import UIKit
import TransmissionRPC

@objcMembers
class TorrentTrackersController: CommonTableController {

    var trackers:[Tracker]!
    var oldBarItems: [UIBarButtonItem]!
    var completionHandler: ((Error?)->Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        trackers = []
        completionHandler =   { error in
            DispatchQueue.main.async {
                if error != nil {
                    displayErrorMessage(error!.localizedDescription, using: self.view.window!.rootViewController)
                }
            }
        }
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updateData), for: .valueChanged)
    }

    /*
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let viewVisualEffect = UIVisualEffectView(effect: blurEffect)
        viewVisualEffect.frame = tableView.bounds
        viewVisualEffect.layer.masksToBounds = true
        self.tableView.backgroundView = viewVisualEffect
        self.tableView.setNeedsDisplay()
        
    }
*/
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        parent!.navigationItem.title = "Trackers"
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus.circle"),style: .plain, target: self, action:#selector(addTracker(_:)))
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(startEdit(_:)))
        parent!.navigationItem.rightBarButtonItems = [editButton,addButton]
    }
    
    
    
    @IBAction func longPress(_ sender:UILongPressGestureRecognizer) {
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action:#selector(doneEdit(_:)))
        parent!.navigationItem.rightBarButtonItems = [doneButton]
        tableView.setEditing(true, animated: true)
    }
    
    
    @objc func doneEdit(_ sender: UIBarButtonItem?) {
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus.circle"),style: .plain, target: self, action:#selector(addTracker(_:)))
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(startEdit(_:)))
        parent!.navigationItem.rightBarButtonItems = [addButton,editButton]
        tableView.setEditing(false, animated: true)
    }
    
    @objc func addTracker(_ sender: UIBarButtonItem) {
        let addAlert = UIAlertController(title: "Add Tracker", message: "Enter the tracker URL: ", preferredStyle: .alert)
        addAlert.addTextField(configurationHandler: { textField in textField.frame.size = CGSize(width: 300, height: 16) })
        let actionAdd = UIAlertAction(title: "Add", style: .default, handler: {_  in
            let rpcArgument = [JSONKeys.trackerAdd: [addAlert.textFields![0].text ?? ""]]
            self.session.setFields(rpcArgument, forTorrents: [self.torrent.trId], completionHandler: self.completionHandler)
            
        })
        addAlert.addAction(actionAdd)
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        addAlert.addAction(actionCancel)
        self.present(addAlert, animated: true, completion: nil)
    }
    
    @objc func startEdit(_ sender: UIBarButtonItem) {
         let addButton = UIBarButtonItem(image: UIImage(systemName: "plus.circle"),style: .plain, target: self, action:#selector(addTracker(_:)))
         let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action:#selector(doneEdit(_:)))
        parent!.navigationItem.rightBarButtonItems = [addButton,doneButton]
        self.tableView.setEditing(true, animated: true)
    }
    
    
    @objc override func updateData(_ sender: Any? = nil) {
        session.getTrackers(forTorrent: torrent.trId) { (trackers, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = error!.localizedDescription
                    return
                }
                self.trackers = trackers!
                if !self.tableView.isEditing {
                    self.tableView.reloadData()
                }
            }
        }
    }
    

    // MARK: - UITableView Protocol
/*    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Tracker list", comment: "")
    }*/
    
/*    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    } */
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackers.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tracker = trackers[indexPath.row]
            // show confirmation dialog
            let removeAlert = UIAlertController(title: "Remove Tracker", message: "Remove Tracker \(tracker.host)?", preferredStyle: .alert)
            removeAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                let rpcArgument = [JSONKeys.trackerRemove: [tracker.trackerId]]
                self.session.setFields(rpcArgument, forTorrents: [self.torrent.trId], completionHandler: self.completionHandler)
                self.trackers.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }))
            removeAlert.addAction(UIAlertAction(title: "No", style: .default, handler:nil))
            self.present(removeAlert, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let info = trackers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_TRACKERINFO, for: indexPath) as! TrackerListCell
        update(cell, withData: info)
        return cell
    }
    
    func update(_ cell: TrackerListCell, withData info: Tracker) {
        cell.trackerId = info.trackerId
        cell.trackerHostLabel.text = info.host
            cell.lastAnnounceTimeLabel.text = NSLocalizedString("Last announce time: \(info.lastAnnounceTimeString) \(info.lastAnnounceResult)", comment: "")

        cell.nextAnnounceTimeLabel.text = NSLocalizedString("Next announce time: \(info.nextAnnounceTimeString)", comment: "")
            cell.lastScrapeTimeLabel.text = NSLocalizedString("Last scrape-announce time: \(info.lastScrapeTimeString) \(info.lastScrapeResult)", comment: "")
       
            cell.nextScrapeTimeLabel.text = NSLocalizedString("Next scrape-announce time: \(info.nextScrapeTimeString)", comment: "")
        
       
            cell.seedersLabel.text = String(format: NSLocalizedString("Seeders: %i", comment: ""), info.seederCount)
        
     
            cell.leechersLabel.text = String(format: NSLocalizedString("Leechers: %i", comment: ""), info.leecherCount)
       
            cell.downloadsLabel.text = String(format: NSLocalizedString("Downloads: %i", comment: ""), info.downloadCount)
        
            cell.peersLabel.text = String(format: NSLocalizedString("Peers: %i", comment: ""), info.lastAnnouncePeerCount)
        
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
