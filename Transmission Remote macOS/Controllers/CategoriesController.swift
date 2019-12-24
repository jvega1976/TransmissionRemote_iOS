//
//  CategoriesController.swift
//  Transmission Remote
//
//  Created by  on 12/11/19.
//

import Cocoa
import TransmissionRPC
import Categorization
import UserNotifications

@objcMembers
class CategoriesController: NSViewController {

    @IBOutlet var categoryArrayController: NSArrayController!
    @IBOutlet weak var tableView: NSTableView!

    
    dynamic var categorization: TorrentCategorization!
    
    dynamic public var categories: Array<TorrentCategory>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.categories = TorrentCategorization.shared.categories
        self.categoryArrayController.content = self.categories
        self.categoryArrayController.rearrangeObjects()
        self.tableView.reloadData()
    }
    
    
}

extension CategoriesController: NSTableViewDataSource, NSTableViewDelegate {
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return self.categories.count
    }
    
    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return categories[row]
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: CategoryCellView
        if let theCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "statusCategory"), owner: self) as? CategoryCellView {
            cell = theCell
        } else {
            cell = CategoryCellView()
        }
        let category = categories[row]
        cell.title.stringValue = category.title
        cell.ItemsCount.integerValue = TorrentCategorization.shared.numberOfItemsInCategory(withTitle: category.title)
        cell.icon.contentColor = category.iconColor
        cell.icon.iconType = category.iconType
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        TorrentCategorization.shared.selectedCategoryIndex = tableView.selectedRow
        //NotificationCenter.default.post(name: .SelectedCategoryChanged, object: nil)
        dismiss(self)
    }
}


extension Notification.Name {
    static let SelectedCategoryChanged = Notification.Name(rawValue: "SelectedCategoryChanged")
}
