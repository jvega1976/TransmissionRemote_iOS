//
//  ScheduleAltLimitController.swift
//  Transmission Remote
//
//  Created by  on 7/29/19.
//

import UIKit

let CELL_ID_DAY = "tableViewCell"
let CONTROLLER_ID_SCHEDULETIMEDATE = "scheduleTimeDayController"

@objcMembers
class ScheduleAltLimitsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
 
    var days: [String] = []
    //NSArray             *_dayNums;
    //NSMutableArray      *_selectedDays;

    var dateBegin: Date?
    var dateEnd: Date?

    var daysMask: Int {
        get {
            var mask = 0

            for i in 0..<dayNums.count {
                let n = dayNums[i]

                if selectedDays[i] {
                    mask |= n
                }
            }

            return mask
        }
        set(daysMask) {
            for i in 0..<dayNums.count {
                let n = dayNums[i]

                selectedDays[i] = (daysMask & n) != 0 ? true : false
            }
        }
    }

    var timeBegin: Int {
        get {
            let dt = dateFrom.date

            let cal = Calendar.current
            let c = cal.dateComponents([.hour, .minute], from: dt)

            return c.hour! * 60 + c.minute!
        }
        set(timeBegin) {
            let c = Calendar.current
            var cp = c.dateComponents([.hour, .minute], from: Date())
            cp.hour = timeBegin / 60
            cp.minute = timeBegin % 60

            dateBegin = c.date(from: cp)

            //[_dateFrom setDate:[c dateFromComponents:cp] animated:YES];
        }
    }

    var timeEnd: Int {
        get {
            let dt = dateTo.date

            let cal = Calendar.current
            let c = cal.dateComponents([.hour, .minute], from: dt)

            return c.hour! * 60 + c.minute!
        }
        set(timeEnd) {
            let c = Calendar.current
            var cp = c.dateComponents([.hour,.minute], from: Date())
            cp.hour = timeEnd / 60
            cp.minute = timeEnd % 60

            dateEnd = c.date(from: cp)
            //[_dateTo setDate:[c dateFromComponents:cp] animated:YES];
        }
    }
    
    @IBOutlet weak var dateTo: UIDatePicker!
    @IBOutlet weak var dateFrom: UIDatePicker!
    @IBOutlet weak var tableDays: UITableView!

    private var dayNums: [Int] = [2, 4, 8, 16, 32, 64, 1]

    private var selectedDays: [Bool] = [false, false, false, false, false, false, false]
 

    override func viewDidLoad() {
        super.viewDidLoad()

        tableDays.dataSource = self
        tableDays.delegate = self

        days = [
        NSLocalizedString("On Mondays", comment: ""),
        NSLocalizedString("On Tuesdays", comment: ""),
        NSLocalizedString("On Wednesdays", comment: ""),
        NSLocalizedString("On Thursdays", comment: ""),
        NSLocalizedString("On Fridays", comment: ""),
        NSLocalizedString("On Saturdays", comment: ""),
        NSLocalizedString("On Sundays", comment: "")
        ]

        //NSLog(@"%s", __PRETTY_FUNCTION__);
    }

    // lazy instntiation

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if dateBegin != nil && dateEnd != nil {
            if let dateBegin = dateBegin {
                dateFrom.date = dateBegin
            }
            if let dateEnd = dateEnd {
                dateTo.date = dateEnd
            }

            tableDays.reloadData()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return days.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Select days", comment: "")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = selectedDays[indexPath.row]
        selectedDays[indexPath.row] = !selected

        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID_DAY, for: indexPath)

        cell.textLabel!.text = days[indexPath.row]
        cell.accessoryType = selectedDays[indexPath.row] ? .checkmark : .none

        return cell
    }

    @IBAction func time(fromChanged sender: UIDatePicker) {
        let dt0 = sender.date
        let dt1 = dateTo.date

        let res = dt0.compare(dt1)
        if res == .orderedDescending || res == .orderedSame {
            let dt = Date(timeInterval: 15 * 60, since: dt0)
            dateTo.setDate(dt, animated: true)
        }
    }

    @IBAction func time(toChanged sender: UIDatePicker) {
        let dt0 = sender.date
        let dt1 = dateFrom.date

        let res = dt0.compare(dt1)
        if res == .orderedAscending || res == .orderedSame {
            let dt = Date(timeInterval: -(15 * 60), since: dt0)
            dateFrom.setDate(dt, animated: true)
        }
    }
}
