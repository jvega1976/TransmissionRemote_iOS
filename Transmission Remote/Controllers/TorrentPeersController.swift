//
//  TorrentPeersController.swift
//  Transmission Remote
//
//  Created by  on 7/16/19.
//

import UIKit
import TransmissionRPC

let ROWHIGHT_PEERINFOHEADER = 52
let ROWHIGHT_PEERINFO = 52
let ROWHIGHT_PEERSTAT = 114

let SECTIONFOOTER_HEIGHT = 237

class TorrentPeersController: CommonTableController {
    
    private var peers: [Peer] = []
    private var sectionTitles: [Any] = []
    private var peerStat: PeerStat!
    private var dataWasSet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sectionTitles = [
            NSLocalizedString("Peers", comment: ""),
            NSLocalizedString("Peers stats", comment: "")
        ]
        
        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(updateData), for: .valueChanged)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        parent!.navigationItem.title = NSLocalizedString("Peers", comment: "")
        parent!.navigationItem.rightBarButtonItems = nil
        
    }

    
    @objc override func updateData(_ sender: Any? = nil) {
        session.getPeers(forTorrent: torrent.trId) { (peers, peerStat, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = error!.localizedDescription
                    return
                }
                self.update(withPeers: peers!, andPeerStat: peerStat!)
            }
        }
        
    }

    
    func update(withPeers peers: [Peer], andPeerStat peerStat: PeerStat) {
        // set flag that tell there is data
        dataWasSet = true
        
        refreshControl?.endRefreshing()
        
        // this is the first data - add section
        if peers.count > 0 && self.peers.count == 0 {
            self.peers = peers
            self.peerStat = peerStat
            tableView.beginUpdates()
            tableView.insertSections(NSIndexSet(indexesIn: NSRange(location: 0, length: 2)) as IndexSet, with: .automatic)
            tableView.endUpdates()
            return
        }
        
        // there is no data - clear section
        if self.peers.count > 0 && peers.count == 0 {
            self.peers = peers
            self.peerStat = peerStat
            tableView.beginUpdates()
            tableView.deleteSections(NSIndexSet(indexesIn: NSRange(location: 0, length: 2)) as IndexSet, with: .automatic)
            tableView.endUpdates()
            return
        }
        
        let count = max(self.peers.count, peers.count)
        
        var indexPathsToAdd: [IndexPath] = []
        var indexPathsToRemove: [IndexPath] = []
        var indexPathsToReload: [IndexPath] = []
        
        var needToUpdate = false
        
        for i in 0..<count {
            let path = IndexPath(row: i + 1, section: 0)
            
            let cur = i < self.peers.count ? self.peers[i] : nil
            let new = i < peers.count ? peers[i] : nil
            
            // there is no current element
            // this index is new and should be re
            if cur == nil {
                indexPathsToAdd.append(path)
                needToUpdate = true
            } else if new == nil {
                indexPathsToRemove.append(path)
                needToUpdate = true
            } else {
                // compare data
                if (cur!.ipAddress == new!.ipAddress) {
                    // update cell
                    let cell = tableView.cellForRow(at: path) as? PeerListCell
                    if cell != nil {
                        update(cell!, withInfo: cur!)
                    }
                } else {
                    indexPathsToReload.append(path)
                    needToUpdate = true
                }
            }
        }
        
        // store data before update animation
        self.peers = peers
        self.peerStat = peerStat
        
        if needToUpdate {
            tableView.beginUpdates()
            
            if indexPathsToAdd.count > 0 {
                tableView.insertRows(at: indexPathsToAdd, with: .automatic)
            }
            
            if indexPathsToRemove.count > 0 {
                tableView.deleteRows(at: indexPathsToRemove, with: .automatic)

            }
            
            if indexPathsToReload.count > 0 {
                tableView.reloadRows(at: indexPathsToReload, with: .automatic)
            }
            
            tableView.endUpdates()
        } else if self.peers.count == 0 {
            tableView.reloadData()
        }
        
        // now we update peer stats
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PeerStatCell
        if cell != nil {
            update(cell!, withStat: peerStat)
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if !dataWasSet {
            return 0
        }
        
        // Return the number of sections.
        infoMessage = peers.count > 0 ? nil : NSLocalizedString("There are no peers avalable.", comment: "")
        
        return peers.count > 0 ? sectionTitles.count : 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section] as? String
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section + 1 for header row
        if section == 0 {
            return peers.count + 1
        }
        
        // second section (PeerStats) has only one row
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return CGFloat(ROWHIGHT_PEERSTAT)
        }
        
        if indexPath.row == 0 {
            return CGFloat(ROWHIGHT_PEERINFOHEADER)
        }
        
        return CGFloat(ROWHIGHT_PEERINFO)
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  header row
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_PEERLISTHEADERCELL, for: indexPath)
            return cell
        }
        
        // peer info
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_PEERLISTCELL, for: indexPath) as? PeerListCell
            let info = peers[indexPath.row - 1]
            update(cell!, withInfo: info)
            
            return cell!
        }
        
        // peer stat section
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_PEERSTAT, for: indexPath) as? PeerStatCell
            update(cell!, withStat: peerStat)
            return cell!
        }
        return UITableViewCell()
    }
    
    func update(_ cell: PeerStatCell, withStat stat: PeerStat) {
        cell.labelFromCache.text = String(stat.fromCache)
        cell.labelFromDht.text = String(stat.fromDht)
        cell.labelFromLpd.text = String(stat.fromLpd)
        cell.labelFromPex.text = String(stat.fromPex)
        cell.labelFromTracker.text = String(stat.fromTracker)
        cell.labelFromIncoming.text = String(stat.fromIncoming)
    }
    
    func update(_ cell: PeerListCell, withInfo info: Peer) {
        cell.clientLabel.text = info.clientName
        cell.addressLabel.text = info.ipAddress
        cell.progressLabel.text = info.progressString
        cell.flagLabel.text = info.flagString
        cell.downloadLabel.text = info.rateToClient > 0 ? info.rateToClientString : "-"
        cell.uploadLabel.text = info.rateToPeer > 0 ? info.rateToPeerString : "-"
        cell.isSecure = info.isEncrypted
        cell.isUTPEnabled = info.isUTP
        let ipConnector = GeoIpConnector()
        var countryName: String!
        var countryCode: String!
        let sema = DispatchSemaphore(value: 0)
        ipConnector.getInfoForIp(info.ipAddress, responseHandler: { (error, dict) in
            if error == nil {
                if dict != nil && (dict!["status"] as! String) == "success" {
                    countryName = dict!["country"] as? String == nil ? "-" : dict!["country"] as! String
                    countryCode = dict!["countryCode"] as? String == nil ? "-" : dict!["countryCode"] as! String
                    
                }
            }
            sema.signal()
        })
        sema.wait()
        cell.countryName.text = countryName ?? ""
        if countryCode != nil {
            cell.countryFlagImage.image = UIImage(named: countryCode)
        }
    }
    

}
