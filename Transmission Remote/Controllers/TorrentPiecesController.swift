//
//  TorrentPiecesController.swift
//  Transmission Remote
//
//  Created by  on 7/16/19.
//

import UIKit
import TransmissionRPC

class TorrentPiecesController: CommonTableController {

    @IBOutlet weak var labelPiecesCount: UILabel!
    @IBOutlet weak var labelPieceSize: UILabel!
    @IBOutlet weak var labelRowsCount: UILabel!
    @IBOutlet weak var labelColumnsCount: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var piecesCount = 0
    private var pieceSize: Int = 0
    private var piecesBitmap: Data?

    private var columns: CGFloat!
    private var rows: CGFloat!
    
    var legendView: PiecesView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        piecesCount = torrent.piecesCount
        pieceSize = torrent.pieceSize
       
    }
    
    
     @objc override func updateData(_ sender: Any? = nil) {
        session.getPieces(forTorrent: torrent.trId) { (data, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = error!.localizedDescription
                    return
                }
                if self.legendView.bits != nil {
                    self.legendView.prevbits = self.legendView.bits
                }
                self.legendView.bits = data! as NSData
                self.legendView.setNeedsDisplay()
            }
        }
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        parent!.navigationItem.rightBarButtonItems = nil
        parent!.navigationItem.title = "Activity"
       
        
        labelPiecesCount.text = String(format: NSLocalizedString("Pieces count: %i", comment: ""), piecesCount)
        labelPieceSize.text = NSLocalizedString("Piece size: \(formatByteCount(pieceSize))", comment: "")

        columns = 50.0
        rows = ceil(CGFloat(piecesCount)/columns)

        labelRowsCount.text = String(format: NSLocalizedString("Rows: %i", comment: ""), Int(rows))
        labelColumnsCount.text = String(format: NSLocalizedString("Columns: %i", comment: ""), Int(columns))

        let bs = scrollView.frame.size
        let pw = splitViewController != nil ? (bs.width - 45) / columns : bs.width / columns
        let ph = pw * 1.4

        scrollView.contentSize = CGSize(width: pw * columns, height: ph * rows)

        legendView = PiecesView(frame: CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        legendView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        legendView.rows = Int(rows)
        legendView.cols = Int(columns)
        legendView.count = piecesCount
        legendView.pw = pw
        legendView.ph = ph

        scrollView.addSubview(legendView)
    }

}
