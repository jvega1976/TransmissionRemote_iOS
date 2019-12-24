//
//  GlobalConsts.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

import UIKit

let TABLEHEADER_ERRORLABEL_TOPBOTTOMMARGIN: CGFloat = 10
let TABLEHEADER_ERRORLABEL_FONTSIZE: CGFloat = 15.0

let TABLEVIEW_BACKGROUND_MESSAGE_FONTSIZE:CGFloat = 15.0
let TABLEVIEW_FOOTER_MESSAGE_FONTSIZE: CGFloat = 14.0
let TABLEVIEW_FOOTER_MESSAGE_TOPBOTTOM_MARGINGS: CGFloat = 30

let TABLEVIEW_HEADER_MESSAGE_TOPBOTTOM_MARGINGS:CGFloat = 30
let TABLEVIEW_HEADER_MESSAGE_FONTSIZE: CGFloat = 14.0

let TORRENT_LIST: String = "TorrentList"

// utility functions
let GLOBAL_CONTROLLERS_STORYBOARD = "Main"

let USERDEFAULTS_BGFETCH_KEY_LAST_TIME = "bgLastTimeCheck"
let USERDEFAULTS_KEY_WEBDAV = "webDAVServerUrl"
/// returns YES if this is iPhone PLUS model on iOS8


var instantiateControllerStoryboard: UIStoryboard? = nil

func instantiateController(_ controllerId: String) -> UIViewController {

    if instantiateControllerStoryboard == nil {
        instantiateControllerStoryboard = UIStoryboard(name: GLOBAL_CONTROLLERS_STORYBOARD, bundle: nil)
    }


    return instantiateControllerStoryboard!.instantiateViewController(withIdentifier: controllerId)
}

func isIPhonePlus() -> Bool {
    if UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.responds(to: #selector(getter: UIScreen.nativeBounds)) {
        let ratio = UIScreen.main.nativeBounds.size.height / UIScreen.main.nativeScale
        return ratio >= 736.0
    }

    return false
}


// UINavigationController bit titles prefer
func preferBigTitleForNavController(_ navVC: UINavigationController?) {
    if #available(iOS 11.0, *) {
        navVC?.navigationBar.prefersLargeTitles = true
        navVC?.navigationItem.largeTitleDisplayMode = .automatic
    }
}

func displayInfoMessage(_ message: String, using controller: UIViewController?) {
    let msg = Bundle.main.loadNibNamed(INFO_MESSAGE_BUNDLENAME, owner: controller, options: nil)?.first as! InfoMessage
    msg.showInfo(message, from: controller?.view)
}


func displayErrorMessage(_ message: String, using controller: UIViewController?) {
    let msg = Bundle.main.loadNibNamed(INFO_MESSAGE_BUNDLENAME, owner: controller, options: nil)?.first as! InfoMessage
    msg.showErrorInfo(message, from: controller?.view)
}
