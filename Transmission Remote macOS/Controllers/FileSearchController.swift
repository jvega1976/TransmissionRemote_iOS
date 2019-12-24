//
//  TorrentSearchController.swift
//  Transmission Remote
//
//  Created by  on 12/25/19.
//

import Cocoa
import TransmissionRPC

class FileSearchController: NSViewController {

    @IBOutlet weak var searchTextField: NSSearchField!
    var torrentFilesController: TorrentFilesController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func searchFiles(_ sender: NSSearchField) {
        var predicate: (FSItem)->Bool
        if sender.stringValue.count > 0 {
            let andWords = sender.stringValue.split(whereSeparator: { $0 == "&" })
            let orWords = sender.stringValue.split(whereSeparator: { $0 == "|" })
            predicate = {fsItem in
                var result = true
                if !andWords.isEmpty {
                    for word in andWords {
                        result = result && fsItem.name.localizedCaseInsensitiveContains(word.trimmingCharacters(in: .whitespaces))
                    }
                }
                if !orWords.isEmpty {
                    for word in orWords {
                        result = result || fsItem.name.localizedCaseInsensitiveContains(word.trimmingCharacters(in: .whitespaces))
                    }
                }
                if orWords.isEmpty && andWords.isEmpty {
                    result = result && fsItem.name.localizedCaseInsensitiveContains(sender.stringValue)
                }
                return result
            }
        } else {
            predicate = {fsItem in return true }
        }
        torrentFilesController.willChangeValue(forKey: #keyPath(TorrentFilesController.files))
        torrentFilesController.fsDir?.rootItem?.filterPredicate = predicate
        torrentFilesController.didChangeValue(forKey: #keyPath(TorrentFilesController.files))
        self.dismiss(self)
    }
}
