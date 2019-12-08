//
//  TorrentCategorization.swift
//  Transmission Remote
//
//  Created by  on 7/14/19.
//

#if os(iOS)
import UIKit
import Categorization
import TransmissionRPC
#else
import AppKit
import Categorization
import TransmissionRPC
#endif




let TR_GL_TITLE_ALL = NSLocalizedString("All", comment: "StatusCategory title")
let TR_GL_TITLE_DOWN = NSLocalizedString("Downloading", comment: "StatusCategory title")
let TR_GL_TITLE_UPL = NSLocalizedString("Seeding", comment: "StatusCategory title")
let TR_GL_TITLE_PAUSE = NSLocalizedString("Stopped", comment: "StatusCategory title")
let TR_GL_TITLE_ACTIVE = NSLocalizedString("Active", comment: "StatusCategory title")
let TR_GL_TITLE_VERIFY = NSLocalizedString("Verifying", comment: "StatusCategory title")
let TR_GL_TITLE_WAIT = NSLocalizedString("Waiting", comment: "StatusCategory title")
let TR_GL_TITLE_ERROR = NSLocalizedString("Error", comment: "StatusCategory title")
let TR_GL_TITLE_COMPL = NSLocalizedString("Completed", comment: "StatusCategory title")

let TR_CAT_IDX_ALL = 0
let TR_CAT_IDX_DOWN = 1
let TR_CAT_IDX_UPL = 2
let TR_CAT_IDX_ACTIVE = 3
let TR_CAT_IDX_WAIT = 4
let TR_CAT_IDX_COMPL = 5
let TR_CAT_IDX_PAUSED = 6
let TR_CAT_IDX_ERROR = 7
let TR_CAT_IDX_VERIFY = 8

typealias TorrentCategory = CategoryDef<Torrent>
typealias TorrentPredicate = Predicate<Torrent>

public class TorrentCategorization: Categorization<Torrent> {
    
    public static var shared = TorrentCategorization()

    override public init () {
        var categoryList = [TorrentCategory]()
        var c: TorrentCategory
        var p: TorrentPredicate
        
        // Fill Categories
        p = {_ in return true}
        c = Category(withTitle: TR_GL_TITLE_ALL, filterPredicate: p, sortIndex: 999, isAlwaysVisible: true)
        categoryList.append(c)
        
        p = { torrent in return torrent.isDownloading } //NSPredicate(format: "isDownloading == YES")
        c = Category(withTitle: TR_GL_TITLE_DOWN, filterPredicate: p, sortIndex: 0, isAlwaysVisible: true)
        categoryList.append(c)
        
        p = { torrent in return torrent.isSeeding } //NSPredicate(format: "isSeeding == YES")
        c = Category(withTitle: TR_GL_TITLE_UPL, filterPredicate: p, sortIndex: 5, isAlwaysVisible: true)
        categoryList.append(c)
        
        p = {torrent in return torrent.downloadRate > 0 || torrent.uploadRate > 0 } //NSPredicate(format: "downloadRate > 0 OR uploadRate > 0")
        c = Category(withTitle: TR_GL_TITLE_ACTIVE, filterPredicate: p, sortIndex: 999, isAlwaysVisible: false)
        categoryList.append(c)
        
        p = {torrent in return torrent.isWaiting } //NSPredicate(format: "isWaiting == YES")
        c = Category(withTitle: TR_GL_TITLE_WAIT, filterPredicate: p, sortIndex: 1, isAlwaysVisible: false)
        categoryList.append(c)
        
        p = {torrent in return torrent.isFinished } //NSPredicate(format: "isFinished == YES")
        c = Category(withTitle: TR_GL_TITLE_COMPL, filterPredicate: p, sortIndex: 6, isAlwaysVisible: true)
        categoryList.append(c)
        
        p = {torrent in return torrent.isStopped }  //NSPredicate(format: "isStopped == YES")
        c = Category(withTitle: TR_GL_TITLE_PAUSE, filterPredicate: p, sortIndex: 2, isAlwaysVisible: false)
        categoryList.append(c)
        
        p = {torrent in return torrent.isError } //NSPredicate(format: "isError == YES")
        c = Category(withTitle: TR_GL_TITLE_ERROR, filterPredicate: p, sortIndex: 3, isAlwaysVisible: false)
        categoryList.append(c)
        
        p = {torrent in return torrent.isChecking } //NSPredicate(format: "isChecking == YES")
        c = Category(withTitle: TR_GL_TITLE_VERIFY, filterPredicate: p, sortIndex: 4, isAlwaysVisible: false)
        categoryList.append(c)
        super.init(withItems: [Torrent](), withCategories: categoryList)
        self.visibleCategoryPredicate = {category in return category.isAlwaysVisible || self.numberOfItemsInCategory(withTitle: category.title) > 0}
        self.isSorted = true
        self.sortPredicate = { $0 > $1 }
    }
    
}



extension TorrentCategory {
    
    var iconType: IconCloudType {
        if(title == TR_GL_TITLE_ERROR) {
            return IconCloudType.Error
        }
        else if(self.title == TR_GL_TITLE_DOWN) {
            return IconCloudType.Download
        }
        else if(title == TR_GL_TITLE_UPL) {
            return IconCloudType.Upload
        }
        else if(title == TR_GL_TITLE_PAUSE) {
            return IconCloudType.Pause
        }
        else if(title == TR_GL_TITLE_WAIT) {
            return IconCloudType.Wait
        }
        else if(title == TR_GL_TITLE_VERIFY) {
            return IconCloudType.Verify
        }
        else if(title == TR_GL_TITLE_ACTIVE) {
            return IconCloudType.Active
        }
        else if(title == TR_GL_TITLE_ALL) {
            return IconCloudType.All
        }
        else if(title == TR_GL_TITLE_COMPL) {
            return IconCloudType.Completed
        }
        return IconCloudType.None
    }
    
    var iconColor: UIColor {
        if(title == TR_GL_TITLE_ERROR) {
            return UIColor.colorError!
        }
        else if(self.title == TR_GL_TITLE_DOWN) {
            return UIColor.colorDownload!
        }
        else if(title == TR_GL_TITLE_UPL) {
            return UIColor.colorUpload!
        }
        else if(title == TR_GL_TITLE_PAUSE) {
            return UIColor.colorPaused!
        }
        else if(title == TR_GL_TITLE_WAIT) {
            return UIColor.colorWait!
        }
        else if(title == TR_GL_TITLE_VERIFY) {
            return UIColor.colorVerify!
        }
        else if(title == TR_GL_TITLE_ACTIVE) {
            return UIColor.colorActive!
        }
        else if(title == TR_GL_TITLE_ALL) {
            return UIColor.colorAll!
        }
        else if(title == TR_GL_TITLE_COMPL) {
            return UIColor.colorCompleted!
        }
        return UIColor.systemFill
    }
    
    public var iconImage: UIImage {
        let icon = IconCloud(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        icon.tintColor = self.iconColor
        icon.iconType = self.iconType
        return icon.image
    }
}
