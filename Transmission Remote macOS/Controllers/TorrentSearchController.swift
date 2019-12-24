//
//  TorrentSearchController.swift
//  Transmission Remote
//
//  Created by  on 12/25/19.
//

import Cocoa
import Categorization

class TorrentSearchController: NSViewController {

    @IBOutlet weak var searchTextField: NSSearchField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func searchTorrents(_ sender: NSSearchField) {
        var predicate: TorrentCategorization.Predicate
        if sender.stringValue.count > 0 {
            let andWords = sender.stringValue.split(whereSeparator: { $0 == "&" })
            let orWords = sender.stringValue.split(whereSeparator: { $0 == "|" })
            predicate = {element in
                var result = true
                if !andWords.isEmpty {
                    for word in andWords {
                        result = result && element.name.localizedCaseInsensitiveContains(word.trimmingCharacters(in: .whitespaces))
                    }
                }
                if !orWords.isEmpty {
                    for word in orWords {
                        result = result || element.name.localizedCaseInsensitiveContains(word.trimmingCharacters(in: .whitespaces))
                    }
                }
                if orWords.isEmpty && andWords.isEmpty {
                    result = result && element.name.localizedCaseInsensitiveContains(sender.stringValue)
                }
                return result
            }
        } else {
            predicate = {element in return true }
        }
        TorrentCategorization.shared.filterPredicate = predicate
        self.dismiss(self)
    }
}
