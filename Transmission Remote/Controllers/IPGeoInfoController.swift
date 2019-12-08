//
//  IPGeoInfoController.swift
//  Transmission Remote
//
//  Created by  on 7/28/19.
//

import UIKit

let CONROLLER_ID_IPGEOINFO = "ipGeoInfoController"
let LABEL_NAME = "freegeoip.net"
let HOST_NAME = "http://freegeoip.net"


@objcMembers
class IPGeoInfoController: UIViewController {
    
    @IBOutlet weak var labelCountry: UILabel!
    @IBOutlet weak var labelCity: UILabel!
    @IBOutlet weak var labelRegion: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var labelError: UILabel!
    var ipAddress = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        navigationController?.isToolbarHidden = false

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.boldSystemFont(ofSize: 13.0)
        label.textColor = label.tintColor
        label.text = LABEL_NAME
        label.isUserInteractionEnabled = true

        label.sizeToFit()

        let rec = UITapGestureRecognizer(target: self, action: #selector(goToSite))
        label.addGestureRecognizer(rec)

        let lblItem = UIBarButtonItem(customView: label)
        toolbarItems = [spacer, lblItem, spacer]

        if ipAddress != "" {
            getInfo()
        }
    }

    @objc func goToSite() {
        //NSLog(@"Tapped");
        if let url = URL(string: HOST_NAME) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func getInfo() {
        indicator.startAnimating()

        let geoConnector = GeoIpConnector()

        geoConnector.getInfoForIp(ipAddress, responseHandler: { error, dict in
            self.indicator.stopAnimating()
            if dict != nil {
                self.labelCountry.text = (dict?["country_name"] as? String == "") ? "-" : (dict?["country_name"] as? String ?? "")
                self.labelCity.text = (dict?["city"] as? String == "") ? "-" : (dict?["city"] as? String ?? "")
                self.labelRegion.text = (dict?["region_name"] as? String == "") ? "-" : (dict?["region_name"] as? String ?? "")
            } else {
                self.labelError.isHidden = false
                self.icon.image = UIImage(named: "iconExclamation36x36")
                self.icon.image = self.icon.image?.withRenderingMode(.alwaysTemplate)
                self.icon.tintColor = UIColor.darkGray
                self.labelError.text = error
            }
        })
    }
}
