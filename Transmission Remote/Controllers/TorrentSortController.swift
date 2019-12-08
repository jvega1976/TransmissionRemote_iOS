//
//  TorrentSortController.swift
//  Transmission Remote
//
//  Created by  on 11/22/19.
//

import UIKit
import TransmissionRPC

class TorrentSortController: UITableViewController {

    var torrentTableController: TorrentTableController!
    let sortValues: Array<String>! = SortField.allValues
    let arrowUpImage = UIImage(systemName: "arrow.up")
    let arrowDownImage = UIImage(systemName: "arrow.down")
    let checkmarkImage: UIImage! = UIImage(systemName: "checkmark")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return sortValues.count
        } else {
            return 2
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "torrentSortCell", for: indexPath)
        cell.indentationWidth = 40 //checkmarkImage.size.width
        // Configure the cell...
        if indexPath.section == 0 {
            cell.textLabel!.text = sortValues[indexPath.row]
            let sortIndex = sortValues.firstIndex(of: torrentTableController.sortedBy.rawValue)
            cell.imageView!.image = sortIndex == indexPath.row ? checkmarkImage : nil
            cell.indentationLevel = cell.imageView!.image == nil ? 1 : 0
        }
        else {
            if indexPath.row == 0 {
                cell.textLabel!.text = "Ascending"
                cell.imageView!.image = torrentTableController.sortDirection == .asc ? checkmarkImage : nil
            }
            else {
                cell.textLabel!.text = "Descending"
                cell.imageView!.image = torrentTableController.sortDirection == .desc ? checkmarkImage : nil
            }
            cell.indentationLevel = cell.imageView!.image == nil ? 1 : 0
        }
        return cell
    }
    

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Sort By"
        } else {
            return "Direction"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let sortField = SortField(rawValue: sortValues[indexPath.row])
            torrentTableController.sortedBy = sortField
            let sortDirection = torrentTableController.sortDirection
            switch (sortField,sortDirection) {
                case (.dateAdded,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.dateAdded! < $1.dateAdded! }
                case (.dateAdded,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.dateAdded! > $1.dateAdded! }
                case (.dateCompleted,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.dateDone! < $1.dateDone! }
                case (.dateCompleted,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.dateDone! > $1.dateDone! }
                case (.name,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.name < $1.name }
                case (.name,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.name > $1.name }
                case (.eta,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.eta < $1.eta }
                case (.eta,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.eta > $1.eta }
                case (.size,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.totalSize < $1.totalSize }
                case (.size,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.totalSize > $1.totalSize }
                case (.percentage,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.percentDone < $1.percentDone }
                case (.percentage,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.percentDone > $1.percentDone }
                case (.downSpeed,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.downloadRate < $1.downloadRate }
                case (.downSpeed,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.downloadRate > $1.downloadRate }
                case (.upSpeed,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.uploadRate < $1.uploadRate }
                case (.upSpeed,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.uploadRate > $1.uploadRate }
                case (.seeds,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.peersGettingFromUs < $1.peersGettingFromUs }
                case (.seeds,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.peersGettingFromUs > $1.peersGettingFromUs }
                case (.peers,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.peersSendingToUs < $1.peersSendingToUs }
                case (.peers,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.peersSendingToUs > $1.peersSendingToUs }
                case (.queuePos,.asc):
                    torrentTableController.categorization.sortPredicate = { $0.queuePosition < $1.queuePosition }
                case (.queuePos,.desc):
                    torrentTableController.categorization.sortPredicate = { $0.queuePosition > $1.queuePosition }
                default:
                    break
            }
            torrentTableController.torrents! = torrentTableController.categorization.itemsforCategory(atPosition: torrentTableController.categoryIndex)
            torrentTableController.tableView.reloadData()
            torrentTableController.torrentsCount.text = torrentTableController.torrents.count != 0 ?  String(torrentTableController.torrents.count) : ""
            torrentTableController.removeBlurEffect()
            self.dismiss(animated: true, completion: nil)
        } else {
            if indexPath.row == 0 {
                torrentTableController.sortDirection = .asc
            } else {
                torrentTableController.sortDirection = .desc
            }
            let indexSet = IndexSet(integer: indexPath.section)
            tableView.reloadSections(indexSet, with: .automatic)
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
