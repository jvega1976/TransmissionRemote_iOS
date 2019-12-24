//
//  SessionConfigController.swift
//  Transmission Remote
//
//  Created by  on 7/29/19.
//

import UIKit
import TransmissionRPC

@objcMembers
class SessionConfigController: CommonTableController {
    
    private var controls: [UIControl] = []
    private var scheduleController: ScheduleAltLimitsController!

    @IBOutlet private weak var switchDownloadRateEnabled: UISwitch!
    @IBOutlet private weak var textDownloadRateNumber: UITextField!
    @IBOutlet private weak var switchUploadRateEnabled: UISwitch!
    @IBOutlet private weak var textUploadRateNumber: UITextField!
    @IBOutlet private weak var switchAltDownloadRateEnabled: UISwitch!
    @IBOutlet private weak var textAltDownloadRateNumber: UITextField!
    @IBOutlet private weak var switchAltUploadRateEnabled: UISwitch!
    @IBOutlet private weak var textAltUploadRateNumber: UITextField!
    @IBOutlet private weak var switchAddPartToUnfinishedFiles: UISwitch!
    @IBOutlet private weak var switchStartDownloadImmidiately: UISwitch!
    @IBOutlet weak var switchTrashTorrentFile: UISwitch!
    @IBOutlet private weak var switchSeedRatioLimitEnabled: UISwitch!
    @IBOutlet private weak var textSeedRatioLimitNumber: UITextField!
    @IBOutlet private weak var switchIdleSeedEnabled: UISwitch!
    @IBOutlet private weak var textIdleSeedNumber: UITextField!
    @IBOutlet private weak var textTotalPeersCountNumber: UITextField!
    @IBOutlet private weak var textPeersPerTorrentNumber: UITextField!
    @IBOutlet private weak var segmentEncryption: UISegmentedControl!
    @IBOutlet private weak var switchDHTEnabled: UISwitch!
    @IBOutlet private weak var switchPEXEnabled: UISwitch!
    @IBOutlet private weak var switchLPDEnabled: UISwitch!
    @IBOutlet private weak var switchUTPEnabled: UISwitch!
    @IBOutlet private weak var switchRandomPortEnabled: UISwitch!
    @IBOutlet private weak var switchPortForwardingEnabled: UISwitch!
    @IBOutlet private weak var textPortNumber: UITextField!
    @IBOutlet private weak var labelPort: UILabel!
    @IBOutlet private weak var indicatorPortCheck: UIActivityIndicatorView!
    @IBOutlet private weak var textDownloadQueue: UITextField!
    @IBOutlet private weak var textSeedQueue: UITextField!
    @IBOutlet private weak var textQueueStalledMinutes: UITextField!
    @IBOutlet private weak var stepperDownloadQueue: UIStepper!
    @IBOutlet private weak var stepperSeedQueue: UIStepper!
    @IBOutlet private weak var stepperQueueStalledMinutes: UIStepper!

    @IBOutlet weak var switchIncompletedDir: UISwitch!
    @IBOutlet weak var textIncompletedDir: UITextField!
    
    @IBOutlet weak var switchScriptDone: UISwitch!
    @IBOutlet weak var textScriptDone: UITextField!
    
    private var _enableControls = false
    private var enableControls: Bool {
        get {
            return _enableControls
        }
        set(enableControls) {
            _enableControls = enableControls
                controls = [
                switchAddPartToUnfinishedFiles,
                switchAltDownloadRateEnabled,
                switchAltUploadRateEnabled,
                switchDHTEnabled,
                switchDownloadRateEnabled,
                switchIdleSeedEnabled,
                switchLPDEnabled,
                switchPEXEnabled,
                switchPortForwardingEnabled,
                switchRandomPortEnabled,
                switchSeedRatioLimitEnabled,
                switchStartDownloadImmidiately,
                switchUploadRateEnabled,
                switchUTPEnabled,
                textAltDownloadRateNumber,
                textAltUploadRateNumber,
                textDownloadRateNumber,
                textIdleSeedNumber,
                textPeersPerTorrentNumber,
                textPortNumber,
                textSeedRatioLimitNumber,
                textSeedRatioLimitNumber,
                textTotalPeersCountNumber,
                textUploadRateNumber,
                segmentEncryption,
                textDownloadDir,
                segmentShowScheduler,
                switchIncompletedDir,
                textIncompletedDir
                ]

            for c in controls {
                c.isEnabled = enableControls
            }
        }
    }
    
    @IBOutlet private weak var textDownloadDir: UITextField!
    @IBOutlet private weak var switchScheduleAltLimits: UISwitch!
    //@property (weak, nonatomic) IBOutlet UIButton *buttonShowScheduler;
    @IBOutlet private weak var segmentShowScheduler: UISegmentedControl!

    public var sessionConfig: SessionConfig!

    private var _portIsOpen = false
    private var portIsOpen: Bool {
        get {
            return _portIsOpen
        }
        set(portIsOpen) {
            indicatorPortCheck.stopAnimating()
            labelPort.textColor = portIsOpen ? UIColor.green : UIColor.red
            labelPort.text = portIsOpen ? NSLocalizedString("OPEN", comment: "Portinfo") : NSLocalizedString("CLOSED", comment: "Portinfo")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        enableControls = false
        let applyButton = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(saveSessionConfig(_:)))
        navigationItem.rightBarButtonItem = applyButton
        title = NSLocalizedString("Settings", comment: "SessionConfigController title")

        segmentShowScheduler.removeSegment(at: 1, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        session.getSessionConfig(withPriority: .veryHigh) { (sessionConfig, error) in
            DispatchQueue.main.async {
                if error == nil  {
                    guard let sessionConfig = sessionConfig else {return}
                    self.sessionConfig = sessionConfig
                    self.loadConfig()
                } else {
                    self.errorMessage = error!.localizedDescription
                }
            }
        }
        saveAltLimitsSchedulerSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    @objc func saveSessionConfig(_ sender:UIBarButtonItem) {
        if saveConfig() {
            session.setSessionConfig(usingConfig: sessionConfig) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        displayErrorMessage(error!.localizedDescription, using: self)
                    }
                    else {
                        displayInfoMessage("Session Configuration was updated", using: self)
                    }
                }
            }
        }
        else {
            return
        }
    }

    func saveAltLimitsSchedulerSettings() {
        segmentShowScheduler.selectedSegmentIndex = -1

        if scheduleController != nil {
            sessionConfig.altSpeedTimeDay = scheduleController!.daysMask
            sessionConfig.altSpeedTimeBegin = scheduleController!.timeBegin
            sessionConfig.altSpeedTimeEnd = scheduleController!.timeEnd
        }
    }

    // returns YES if config values is ok
    func saveConfig() -> Bool {
        sessionConfig.speedLimitDownEnabled = switchDownloadRateEnabled.isOn
        sessionConfig.speedLimitUpEnabled = switchUploadRateEnabled.isOn

        let downloadDir = textDownloadDir.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (downloadDir?.count ?? 0) < 1 {
            errorMessage = NSLocalizedString("You shoud set download directory", comment: "")
            return false
        }

        sessionConfig.downloadDir = downloadDir ?? ""

            sessionConfig.speedLimitDown = Int(textDownloadRateNumber.text ?? "") ?? 0
        if sessionConfig.speedLimitDown <= 0 || sessionConfig.speedLimitDown >= 1000000 {
            errorMessage = NSLocalizedString("Wrong download rate limit", comment: "")
            return false
        }
        
        sessionConfig.incompletedDirEnabled = switchIncompletedDir.isOn
        let incompletedDir = textIncompletedDir.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if sessionConfig.incompletedDirEnabled && (incompletedDir?.count ?? 0 ) < 1 {
            errorMessage = NSLocalizedString("You shoud set incompleted directory", comment: "")
            return false
        }
        sessionConfig.incompletedDir = incompletedDir ?? ""

        sessionConfig.speedLimitUp = Int(textUploadRateNumber.text ?? "") ?? 0
        if sessionConfig.speedLimitUp <= 0 || sessionConfig.speedLimitDown >= 1000000 {
                errorMessage = NSLocalizedString("Wrong upload rate limit", comment: "")
                return false
            }
        
        sessionConfig.altSpeedEnabled = switchAltDownloadRateEnabled.isOn || switchAltUploadRateEnabled.isOn
            sessionConfig.altSpeedDown = Int(textAltDownloadRateNumber.text ?? "") ?? 0
        if sessionConfig.altSpeedDown <= 0 || sessionConfig.altSpeedDown >= 1000000 {
                errorMessage = NSLocalizedString("Wrong alternative download rate limit", comment: "")
                return false
            }

            sessionConfig.altSpeedUp = Int(textAltUploadRateNumber.text ?? "") ?? 0
        if sessionConfig.altSpeedUp <= 0 || sessionConfig.altSpeedUp >= 1000000 {
                errorMessage = NSLocalizedString("Wrong alternative upload rate limit", comment: "")
                return false
            }
        

        sessionConfig.renamePartialFiles = switchAddPartToUnfinishedFiles.isOn
        sessionConfig.startAddedTorrents = switchStartDownloadImmidiately.isOn
        sessionConfig.trashOriginalTorrentFiles = switchTrashTorrentFile.isOn
        
        sessionConfig.seedRatioLimited = switchSeedRatioLimitEnabled.isOn
        sessionConfig.seedRatioLimit = Double(Float(textSeedRatioLimitNumber.text ?? "") ?? 0.0)
        if sessionConfig.seedRatioLimit <= 0 {
                errorMessage = NSLocalizedString("Wrong seed ratio limit factor", comment: "")
                return false
            }
        

        sessionConfig.idleSeedingLimitEnabled = switchIdleSeedEnabled.isOn
            sessionConfig.idleSeedingLimit = Int(textIdleSeedNumber.text ?? "") ?? 0
        if sessionConfig.idleSeedingLimit <= 0 {
                errorMessage = NSLocalizedString("Wrong seed idle timeout number", comment: "")
                return false
            }

        sessionConfig.peerLimitGlobal = Int(textTotalPeersCountNumber.text ?? "") ?? 0

        if sessionConfig.peerLimitGlobal <= 0 {
            errorMessage = NSLocalizedString("Wrong total peers count", comment: "")
            return false
        }

        sessionConfig.peerLimitPerTorrent = Int(textPeersPerTorrentNumber.text ?? "") ?? 0
        if sessionConfig.peerLimitPerTorrent > sessionConfig.peerLimitGlobal {
            errorMessage = NSLocalizedString("Wrong peers per torrent count", comment: "")
            return false
        }

        sessionConfig.encryptionId = segmentEncryption.selectedSegmentIndex

        sessionConfig.dhtEnabled = switchDHTEnabled.isOn
        sessionConfig.pexEnabled = switchPEXEnabled.isOn
        sessionConfig.lpdEnabled = switchLPDEnabled.isOn
        sessionConfig.utpEnabled = switchUTPEnabled.isOn

        sessionConfig.portForfardingEnabled = switchPortForwardingEnabled.isOn
        sessionConfig.peerPortRandomOnStart = switchRandomPortEnabled.isOn

            sessionConfig.peerPort = Int(textPortNumber.text ?? "") ?? 0
        if sessionConfig.peerPort <= 0 || sessionConfig.peerPort > 65535 {
                errorMessage = NSLocalizedString("Wrong port number", comment: "")
                return false
            }
        

        sessionConfig.altSpeedEnabled = switchScheduleAltLimits.isOn

        if switchScheduleAltLimits.isOn {
            saveAltLimitsSchedulerSettings()
        }
        
        sessionConfig.downloadQueueSize = Int(textDownloadQueue.text ?? "0") ?? 0
        sessionConfig.seedQueueSize = Int(textSeedQueue.text ?? "0") ?? 0
        sessionConfig.queueStalledMinutes = Int(textQueueStalledMinutes.text ?? "0") ?? 0

        sessionConfig.scriptTorrentDoneEnabled = switchScriptDone.isOn
        sessionConfig.scriptTorrentDoneFilename = textScriptDone.text ?? ""
        
        errorMessage = nil
        return true
    }

    func loadConfig() {
        if sessionConfig != nil {
            enableControls = true
            // load config values
            switchDownloadRateEnabled.isOn = sessionConfig.speedLimitDownEnabled
            textDownloadRateNumber.isEnabled = sessionConfig.speedLimitDownEnabled
            let downLimitRate = sessionConfig.speedLimitDown
            textDownloadRateNumber.text = String(format: "%i", downLimitRate)
            
            switchIncompletedDir.isOn = sessionConfig.incompletedDirEnabled
            textIncompletedDir.isEnabled = switchIncompletedDir.isOn
            
            if textIncompletedDir.isEnabled {
                textIncompletedDir.text = sessionConfig.incompletedDir
            }
            
            switchUploadRateEnabled.isOn = sessionConfig.speedLimitUpEnabled
            textUploadRateNumber.isEnabled = sessionConfig.speedLimitUpEnabled
            let upLimitRate = sessionConfig.speedLimitUp
            textUploadRateNumber.text = String(format: "%i", upLimitRate)

            switchAltDownloadRateEnabled.isOn = sessionConfig.altSpeedEnabled
            switchAltUploadRateEnabled.isOn = sessionConfig.altSpeedEnabled

            textAltDownloadRateNumber.isEnabled = sessionConfig.altSpeedEnabled
            textAltUploadRateNumber.isEnabled = sessionConfig.altSpeedEnabled
            let altDownloadRateLimit = sessionConfig.altSpeedDown
            textAltDownloadRateNumber.text = String(format: "%i", altDownloadRateLimit)
            let altUploadRateLimit = sessionConfig.altSpeedUp
            textAltUploadRateNumber.text = String(format: "%i", altUploadRateLimit)

            switchAddPartToUnfinishedFiles.isOn = sessionConfig.renamePartialFiles
            switchStartDownloadImmidiately.isOn = sessionConfig.startAddedTorrents
            switchTrashTorrentFile.isOn = sessionConfig.trashOriginalTorrentFiles

            switchSeedRatioLimitEnabled.isOn = sessionConfig.seedRatioLimited
            textSeedRatioLimitNumber.isEnabled = sessionConfig.seedRatioLimited
            let seedRatioLimit = sessionConfig.seedRatioLimit
            textSeedRatioLimitNumber.text = String(format: "%0.1f", seedRatioLimit)
            

            switchIdleSeedEnabled.isOn = sessionConfig.idleSeedingLimitEnabled
            textIdleSeedNumber.isEnabled = sessionConfig.idleSeedingLimitEnabled
            let seedIdleLimit = sessionConfig.idleSeedingLimit
            textIdleSeedNumber.text = String(format: "%i", seedIdleLimit)

            let globalPeerLimit = sessionConfig.peerLimitGlobal
            textTotalPeersCountNumber.text = String(format: "%i", globalPeerLimit)

            let torrentPeerLimit = sessionConfig.peerLimitPerTorrent
            textPeersPerTorrentNumber.text = String(format: "%i", torrentPeerLimit)

            segmentEncryption.selectedSegmentIndex = sessionConfig.encryptionId
            switchDHTEnabled.isOn = sessionConfig.dhtEnabled
            switchPEXEnabled.isOn = sessionConfig.pexEnabled
            switchLPDEnabled.isOn = sessionConfig.lpdEnabled
            switchUTPEnabled.isOn = sessionConfig.utpEnabled

            switchRandomPortEnabled.isOn = sessionConfig.peerPortRandomOnStart
            textPortNumber.isEnabled = !(sessionConfig.peerPortRandomOnStart)
            let port = sessionConfig.peerPort
            textPortNumber.text = String(format: "%i", port)
            switchPortForwardingEnabled.isOn = sessionConfig.portForfardingEnabled

            textDownloadQueue.text = String(sessionConfig.downloadQueueSize )
            stepperDownloadQueue.value = Double(sessionConfig.downloadQueueSize )
            textSeedQueue.text = String(sessionConfig.seedQueueSize )
            stepperSeedQueue.value = Double(sessionConfig.seedQueueSize )
            textQueueStalledMinutes.text = String(sessionConfig.queueStalledMinutes )
            stepperQueueStalledMinutes.value = Double(sessionConfig.queueStalledMinutes )
            
            labelPort.text = NSLocalizedString("testing ...", comment: "")
            indicatorPortCheck.isHidden = false
            indicatorPortCheck.startAnimating()

            textDownloadDir.isEnabled = true
            textDownloadDir.text = sessionConfig.downloadDir

            switchScheduleAltLimits.isEnabled = true
            switchScheduleAltLimits.isOn = sessionConfig.altSpeedEnabled
            //_buttonShowScheduler.enabled = _switchScheduleAltLimits.on;
            segmentShowScheduler.isEnabled = switchScheduleAltLimits.isOn
            segmentShowScheduler.selectedSegmentIndex = -1

            switchScriptDone.isOn = sessionConfig.scriptTorrentDoneEnabled
            textScriptDone.isEnabled = sessionConfig.scriptTorrentDoneEnabled
            textScriptDone.text = sessionConfig.scriptTorrentDoneFilename
            
            let transmissionVersion = sessionConfig.version
            headerInfoMessage = "Transmission \(transmissionVersion)"
            let rpcVersion = sessionConfig.rpcVersion
            footerInfoMessage = NSLocalizedString("RPC Version: \(rpcVersion)", comment: "")
        }
    }

    
    @IBAction func toggleIncompletedDir(_ sender: UISwitch) {
        textIncompletedDir.isEnabled = sender.isOn
        if sender.isOn {
            textIncompletedDir.textColor = .label
        } else {
            textIncompletedDir.textColor = .secondaryLabel
        }
    }
    
    @IBAction func toggleUploadRate(_ sender: UISwitch) {
        textUploadRateNumber.isEnabled = sender.isOn
        var userInfo: [String: Any] = ["SpeedType": "Upload"]
        userInfo["isOn"] = sender.isOn
        NotificationCenter.default.post(name: .ChangeIconSpeedColor, object: nil, userInfo: userInfo)
    }

    @IBAction func toggleDownloadRate(_ sender: UISwitch) {
        textDownloadRateNumber.isEnabled = sender.isOn
        var userInfo: [String: Any] = ["SpeedType": "Download"]
        userInfo["isOn"] = sender.isOn
        NotificationCenter.default.post(name: .ChangeIconSpeedColor, object: nil, userInfo: userInfo)
    }

    @IBAction func toggleAltRate(_ sender: UISwitch) {
        let on = sender.isOn
        textAltDownloadRateNumber.isEnabled = on
        textAltUploadRateNumber.isEnabled = on
        switchAltDownloadRateEnabled.isOn = on
        switchAltUploadRateEnabled.isOn = on
    }

    @IBAction func toggleSeedRatioLimit(_ sender: UISwitch) {
        textSeedRatioLimitNumber.isEnabled = sender.isOn
    }

    @IBAction func toggleIdleSeedLimit(_ sender: UISwitch) {
        textIdleSeedNumber.isEnabled = sender.isOn
    }

    @IBAction func toggleRandomPort(_ sender: UISwitch) {
        textPortNumber.isEnabled = sender.isOn
    }
    
    @IBAction func toggleScriptDone(_ sender: UISwitch) {
        textScriptDone.isEnabled = sender.isOn
    }

    @IBAction func stepperDownloadQueueChanged(_ sender: UIStepper) {
        textDownloadQueue.text = String(Int(sender.value))
    }
    
    @IBAction func stepperSeedQueueChanged(_ sender: UIStepper) {
        textSeedQueue.text = String(Int(sender.value))
    }
    
    @IBAction func stepperStalledMinutesChanged(_ sender: UIStepper) {
        textQueueStalledMinutes.text = String(Int(sender.value))
    }
    
    @IBAction func btnShowScheduler(_ sender: UISegmentedControl) {
        if switchScheduleAltLimits.isOn {
            scheduleController = (instantiateController(CONTROLLER_ID_SCHEDULETIMEDATE) as! ScheduleAltLimitsController)
            scheduleController.title = NSLocalizedString("Schedule time", comment: "")

            //NSLog(@"Setting values ...");
            scheduleController.daysMask = sessionConfig.altSpeedTimeDay
            scheduleController.timeBegin = sessionConfig.altSpeedTimeBegin
            scheduleController.timeEnd = sessionConfig.altSpeedTimeEnd

            navigationController!.pushViewController(scheduleController, animated: true)
        }
    }
    

    @IBAction func schedule(onOff sender: UISwitch) {
        segmentShowScheduler.isEnabled = sender.isOn
    }

}
