//
//  TorrentsSearchController.swift
//  Transmission Remote
//
//  Created by  on 7/20/19.
//

import UIKit
import UICategorization
import TransmissionRPC

class TorrentSearchController: UIViewController, RPCConnectorDelegate {

    var serverConfig: RPCServerConfig!
    var category: Category!
    
//    @IBOutlet weak var searchView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.search, target: self, action: #selector(search(_:)))
        self.navigationItem.rightBarButtonItems = [searchButton]

        // Do any additional setup after loading the view.
    }
    
    @IBAction func search(_ sender: UIBarButtonItem) {
        view.subviews[0].isHidden = !view.subviews[0].isHidden
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showTorrentList") {
            let torrentListController = segue.destination as! TorrentListController
            torrentListController.serverConfig = serverConfig
            torrentListController.category = category
        }
    }

}
