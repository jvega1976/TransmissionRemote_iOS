//
//  SessionController.swift
//  Transmission Remote
//
//  Created by  on 1/2/20.
//

import Cocoa
import TransmissionRPC

class SessionConfigController: NSViewController {

    @IBOutlet weak var downloadDirTextField: NSTextField!
    
    @IBOutlet weak var incompletedDirSwitch: NSSwitch!
    @IBOutlet weak var incompletedDirTextField: NSTextField!
    
    @IBOutlet weak var addPartIncompletedSwitcy: NSSwitch!
    
    @IBOutlet weak var startDownloadSwitch: NSSwitch!
    
    @IBOutlet weak var trashOriginalFileSwitch: NSSwitch!
    
    @IBOutlet weak var sessionConfigTabView: NSTabView!
    
    @IBOutlet weak var tabButtonsStackView: NSStackView!
    
    var actualTab: NSButton?
    
    var tabButtons : Array<NSButton>!
    
    @objc dynamic var sessionConfig: SessionConfig!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        RPCSession.shared?.getSessionConfig(andCompletionHandler: { sessionConfig, error in
            DispatchQueue.main.async {
                if error != nil {
                    InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                } else {
                    self.sessionConfig = sessionConfig
                    //self.loadConfig()
                }
            }
        })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.tabButtons = (self.tabButtonsStackView.arrangedSubviews.filter { $0 is NSButton } as! Array<NSButton>)
        self.actualTab = self.tabButtons.first(where: {$0.identifier == NSUserInterfaceItemIdentifier(rawValue: "files")
            
        })
        sessionConfigTabView.selectTabViewItem(withIdentifier: "files")
        
    }
    
    @objc func loadConfig() {
        downloadDirTextField.stringValue = self.sessionConfig.downloadDir
        incompletedDirSwitch.state = self.sessionConfig.incompletedDirEnabled ? .on : .off
        incompletedDirTextField.stringValue = self.sessionConfig.incompletedDir
        addPartIncompletedSwitcy.state = self.sessionConfig.renamePartialFiles ? .on : .off
        startDownloadSwitch.state = self.sessionConfig.startAddedTorrents ? .on : .off
        trashOriginalFileSwitch.state = self.sessionConfig.trashOriginalTorrentFiles ? .on : .off
    }
    
    @IBAction @objc func selectTabView(_ sender: NSButton) {
        
        self.actualTab?.state = .off
        
        self.sessionConfigTabView.selectTabViewItem(withIdentifier: sender.identifier as Any)
        sender.state = .on
        
        self.actualTab = sender
    }
    
    @IBAction func updateAltLimitDay(_ sender: NSButton) {
        sessionConfig.altSpeedTimeDay = sender.selectedTag()
        self.updateSessionConfig(sender)
    }
    
    @IBAction @objc func updateSessionConfig( _ sender: NSResponder) {
        
       /* if let button = sender as? NSButton {
            if let stackView = button.superview as? NSStackView,
                stackView.orientation == .vertical {
                if let superView = stackView.superview as? NSStackView {
                    for view in superView.arrangedSubviews.filter({$0 is NSButton && ($0 as? NSButton)?.state == .on}) {
                        (view as! NSButton).state = .off
                    }
                }
            }
            else if let stackView = button.superview as? NSStackView,
                stackView.orientation == .horizontal {
                if let subView = stackView.subviews.first(where: {$0 is NSStackView && ($0 as? NSStackView)?.orientation == .vertical }) as? NSStackView {
                    for view in subView.arrangedSubviews.filter({$0 is NSButton && ($0 as? NSButton)?.state == .on}) {
                        (view as! NSButton).state = .off
                    }
                }
            }
            
        }*/

        RPCSession.shared?.setSessionConfig(usingConfig: self.sessionConfig, withPriority: .veryHigh, andCompletionHandler: { error in
             DispatchQueue.main.async {
                if error != nil {
                    InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                    RPCSession.shared?.getSessionConfig(withPriority: .veryHigh, andCompletionHandler: { sessionConfig, error in
                        DispatchQueue.main.async {
                            if error != nil {
                                InfoMessage.displayErrorMessage(error!.localizedDescription, in: self.view)
                            } else {
                                self.setValue(sessionConfig, forKey: "sessionConfig")
                            }
                        }
                    })
                
                }
            }
        })
    }
    
}
