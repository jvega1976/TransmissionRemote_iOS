//
//  AddFileController.swift
//  Transmission Remote
//
//  Created by  on 7/31/19.
//

import UIKit
import TransmissionRPC

let CONTROLLER_ID_CHOOSESERVER = "addFileController"
let CELL_ID_FILESTODOWNLOAD = "filesToDownloadCell"
let CELL_ID_TRACKERLIST = "trackerListCell"

@objcMembers
class AddFileController: CommonTableController {
    private var sectionTitles: [String] = []
    private var selectedRow = 0
    private var fileList: TorrentFilesController!

    private(set) var rpcConfig: RPCServerConfig?
 // using only for returning config
    public var bandwidthPriority = 1

    var startImmidiately = false
    var files: FSDirectory?
    var announceList: [String] = []
    var isMagnet = false

    @IBOutlet var torrentTitleSectionView: TorrentTitleHeaderSectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Add torrent", comment: "Choose server controller title")

        sectionTitles = [
        "",
        NSLocalizedString("Choose server to add torrent", comment: "Section title"),
        NSLocalizedString("Additional parameters", comment: "Section title"),
        NSLocalizedString("Tracker list", comment: "")
        ]
        selectedRow = 0

        bandwidthPriority = 1
        startImmidiately = true
        rpcConfig = ServerConfigDB.shared.db.first
    }

    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    @objc func swithValueChanged(_ sender: UISwitch?) {
        startImmidiately = sender?.isOn ?? false
    }

    @objc func priorityChanged(_ sender: UISegmentedControl?) {
        bandwidthPriority = Int(sender?.selectedSegmentIndex ?? 0)
    }

    /// set torrent title
    func setTorrentTitle(_ titleStr: String?, andTorrentSize sizeStr: String?) {
        let alignStyle = NSMutableParagraphStyle()
        alignStyle.alignment = .left

        let sizeRightStr = NSLocalizedString("Torrent size: ", comment: "")

        var helpStr = ""

        if isMagnet {
            helpStr = NSLocalizedString("MagnetHelpString", comment: "")
        }

        let s = NSMutableAttributedString(string: "\(titleStr ?? "")\n\(sizeRightStr)\(sizeStr ?? "")\(helpStr)", attributes: [
            NSAttributedString.Key.paragraphStyle: alignStyle
        ])

        let titleRange = NSRange(location: 0, length: titleStr?.count ?? 0)
        let sizeRightRange = NSRange(location: (titleStr?.count ?? 0) + 1, length: sizeRightStr.count)
        let sizeRange = NSRange(location: (titleStr?.count ?? 0) + sizeRightStr.count + 1, length: sizeStr?.count ?? 0)

        if isMagnet {
            let helpRange = NSRange(location: sizeRange.location + sizeRange.length, length: helpStr.count)

            s.addAttribute(.font, value: UIFont.systemFont(ofSize: 11), range: helpRange)
            s.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: helpRange)
        }

        s.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16.0), range: titleRange)
        s.addAttribute(.font, value: UIFont.systemFont(ofSize: 13.0), range: sizeRightRange)
        s.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 13.0), range: sizeRange)

        s.addAttribute(.foregroundColor, value: UIColor.label, range: titleRange)
        s.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: sizeRightRange)
        s.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: sizeRange)

        torrentTitleSectionView?.labelTitle.attributedText = s
    }

// MARK: - TableView Delegate methods
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return torrentTitleSectionView
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return torrentTitleSectionView?.bounds.size.height ?? 0.0
        }

        return UITableView.automaticDimension
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return announceList.count > 0 ? sectionTitles.count : sectionTitles.count - 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // just a header (has no rows) - Torrent or Magnet title
        if section == 0 {
            return 0
        }

        // server list
        if section == 1 {
            return ServerConfigDB.shared.db.count
        }

        // section with add torrent parameters
        if section == 2 {
            return files != nil ? 3 : 2
        }

        // the last section has tracker list
        return announceList.count
    }

    // row selection handler
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // check remote server
        if indexPath.section == 1 {
            selectedRow = indexPath.row
            rpcConfig = ServerConfigDB.shared.db[indexPath.row]
            self.tableView.reloadData()
        } else if indexPath.section == 2 && indexPath.row == 2 {
            fileList = instantiateController(CONTROLLER_ID_FILELIST) as? TorrentFilesController
            fileList.addingTorrent = true
            fileList.fsDir = files!
            fileList.selectOnly = true
            fileList.title = NSLocalizedString("Select files to download", comment: "UIViewController Title")
            navigationController!.pushViewController(fileList, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 70
        } else if indexPath.section == 2 || indexPath.section == 3 {
            return 44
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return UITableViewCell()
        }

        // choose server to add torrent
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_CHOOSESERVER, for: indexPath) as! AddTorrentCell
            let config = ServerConfigDB.shared.db[indexPath.row]

            cell.labelServerName.text = config.name
            cell.labelServerUrl.text = config.urlString

            if selectedRow == indexPath.row {
                cell.accessoryType = UITableViewCell.AccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCell.AccessoryType.none
            }

            return cell
        }

        // additional paramters
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_BANDWIDTHPRIORITY, for: indexPath) as! BandwidthPriorityCell
                cell.segment.selectedSegmentIndex = bandwidthPriority
                cell.segment.addTarget(self, action: #selector(priorityChanged(_:)), for: .valueChanged)
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_STARTIMMIDIATELY, for: indexPath) as! StartImmidiatelyCell
                cell.swith.isOn = startImmidiately
                cell.swith.addTarget(self, action: #selector(swithValueChanged(_:)), for: .valueChanged)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_FILESTODOWNLOAD, for: indexPath)
                return cell
            }
        }

        // tracker list
        if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_TRACKERLIST, for: indexPath) as! TrackerListCell
            cell.trackerHostLabel.text = announceList[indexPath.row]
            return cell
        }

        return UITableViewCell()
    }
}
