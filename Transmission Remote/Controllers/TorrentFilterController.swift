//
//  TorrentFilterController.swift
//  Transmission Remote
//
//  Created by  on 11/10/19.
//

import UIKit

class TorrentFilterController: UITableViewController {

    var torrentTableController: TorrentTableController!
    
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return torrentTableController.categorization.categories.count
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Tells iOS that we do NOT want to adapt the presentation style for iPhone
        return .none
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "torrentFilterCell", for: indexPath) as! FilterViewCell

        // Configure the cell...
        let category = torrentTableController.categorization.categories[indexPath.row]
        cell.iconCategory.tintColor = category.iconColor
        cell.iconCategory.iconType = category.iconType
        cell.labelCategory.text = category.title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        torrentTableController.category = torrentTableController.categorization.categories[indexPath.row]
        torrentTableController.categorization.selectedCategoryIndex = indexPath.row
        torrentTableController.tableView.reloadData()
        torrentTableController.torrentsCount.text = torrentTableController.torrents.count != 0 ?  String(torrentTableController.torrents.count) : ""
        torrentTableController.removeBlurEffect()
        self.dismiss(animated: true, completion: nil)
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
