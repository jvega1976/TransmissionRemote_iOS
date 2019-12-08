//
//  CommonTableController.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

import UIKit
import TransmissionRPC


@IBDesignable class CommonTableController: UITableViewController, RefreshTimer {
    
    private var _errorMessage: String!
    /// Table background view message (UILabel text)
    private var _infoMessage: String!
    /// Table footer info message
    var footerInfoMessage: String?
    /// Table header info message
    var headerInfoMessage: String?
    
    private var errorLabel: UILabel?
    private var infoLabel: UILabel?
    private var footerLabel: UILabel?
    private var headerLabel: UILabel?
    
    public var torrent: Torrent!
    public var session: RPCSession!
//    public var detailTorrentController: TorrentDetailsController!

    /// set nil string to hide error message from top
    var errorMessage: String? {
        set(newErrorMessage) {
        _errorMessage = newErrorMessage
        // lazy instantiation
        if errorLabel == nil {
            errorLabel = UILabel(frame: CGRect.zero)
            errorLabel?.backgroundColor = UIColor.colorError
            errorLabel?.textColor = UIColor.white
            errorLabel?.numberOfLines = 0
            errorLabel?.font = UIFont.systemFont(ofSize: TABLEHEADER_ERRORLABEL_FONTSIZE)
            errorLabel?.textAlignment = .center
        }

        if _errorMessage != nil {
            errorLabel?.text = _errorMessage
            errorLabel?.sizeToFit()
            
            var r = tableView.bounds
            r.size.height = (errorLabel?.bounds.size.height ?? 0.0) //+ TABLEHEADER_ERRORLABEL_TOPBOTTOMMARGIN
            errorLabel?.bounds = r

            tableView.tableHeaderView = errorLabel
            tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        } else if tableView.tableHeaderView == errorLabel {
            tableView.tableHeaderView = nil
        }
        }
        get {
            return _errorMessage
        }
    }

    var infoMessage: String! {
        set(newInfoMessage) {
            _infoMessage = newInfoMessage

            if infoLabel == nil {
                infoLabel = UILabel(frame: CGRect.zero)
                infoLabel?.backgroundColor = UIColor.secondaryLabel
                infoLabel?.textColor = UIColor.systemFill
                infoLabel?.font = UIFont.systemFont(ofSize: TABLEVIEW_BACKGROUND_MESSAGE_FONTSIZE)
                infoLabel?.numberOfLines = 0
                infoLabel?.textAlignment = .center
            }

            if infoMessage != nil {
                infoLabel?.text = infoMessage
                var r = tableView.bounds
                r.size.height = (infoLabel?.bounds.size.height ?? 0.0)
                infoLabel?.frame = r

                tableView.tableHeaderView = infoLabel
                tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
            } else {
                tableView.backgroundView = nil
            }
        }
        get {
            return _infoMessage
        }
        
    }

    @objc func footerInfoMessage(_ footerInfoMessage: String?) {
        self.footerInfoMessage = footerInfoMessage

        if footerLabel == nil {
            // show message at bottom
            footerLabel = UILabel(frame: CGRect.zero)
            footerLabel?.textAlignment = .center
            footerLabel?.textColor = UIColor.gray
            footerLabel?.font = UIFont.systemFont(ofSize: TABLEVIEW_FOOTER_MESSAGE_FONTSIZE)
            footerLabel?.numberOfLines = 0
        }

        if footerInfoMessage != nil {
            let newLineRange = (footerInfoMessage as NSString?)?.range(of: "\n")
            footerLabel?.numberOfLines = newLineRange?.length == 0 ? 1 : 0

            footerLabel?.text = footerInfoMessage
            footerLabel?.sizeToFit()
            var r = tableView.bounds
            r.size.height = (footerLabel?.bounds.size.height ?? 0.0) + TABLEVIEW_FOOTER_MESSAGE_TOPBOTTOM_MARGINGS
            tableView.tableFooterView = footerLabel
        } else {
            tableView.tableFooterView = nil
        }
    }

    @objc func headerInfoMessage(_ headerInfoMessage: String?) {
        self.headerInfoMessage = headerInfoMessage

        // show message at bottom
        if headerLabel == nil {
            headerLabel = UILabel(frame: CGRect.zero)
            headerLabel?.textAlignment = .center
            headerLabel?.textColor = UIColor.gray
            headerLabel?.font = UIFont.systemFont(ofSize: TABLEVIEW_HEADER_MESSAGE_FONTSIZE)
            headerLabel?.numberOfLines = 0
        }

        if headerInfoMessage != nil {
            let newLineRange = (headerInfoMessage as NSString?)?.range(of: "\n")
            headerLabel?.numberOfLines = newLineRange?.length == 0 ? 1 : 0
            headerLabel?.text = headerInfoMessage
            headerLabel?.sizeToFit()

            var r = tableView.bounds
            r.size.height = (headerLabel?.bounds.size.height ?? 0.0) + 20

            headerLabel?.bounds = r
            tableView.tableHeaderView = headerLabel
        } else {
            tableView.tableHeaderView = nil
        }
    }
    
    @objc func updateData(_ sender:Any? = nil) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let session = RPCSession.shared else { return }
        self.session = session
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRefresh()  //Method inherited from RefreshTimer Protocol
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startTimer(_:)),
                                               name: .EnableTimers, object: nil)
    }
    
    @objc func startTimer(_ notification: Notification? = nil) {
        if notification != nil {
            try? RPCSession.shared?.restart()
        }
        startRefresh() //Method inherited from RefreshTimer Protocol
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRefresh() //Method inherited from RefreshTimer Protocol
        NotificationCenter.default.removeObserver(self, name:  .EnableTimers, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
}
