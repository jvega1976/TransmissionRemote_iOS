//
//  TorrentDetailsController.swift
//  Transmission Remote
//
//  Created by  on 7/16/19.
//

import UIKit
import TransmissionRPC

class TorrentDetailsController: UITabBarController {

    var torrent: Torrent!
    var torrentListController: TorrentListController!
    
    func fillNavItems() {
        self.navigationItem.leftBarButtonItem = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fillNavItems()
        for controller in viewControllers ?? [] {
            if let controller = controller as? CommonTableController {
                controller.torrent = torrent
            } else if let controller = controller as? TorrentFilesController {
                controller.torrent = torrent
//                controller.commonTableController.detailTorrentController = self
            }
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
}
