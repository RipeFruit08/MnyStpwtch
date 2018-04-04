//
//  HistoryDetailsViewController.swift
//  Timer
//
//  Created by Stephen Kim on 4/2/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import UIKit

class HistoryDetailsViewController: UIViewController {

    var passedData: String?
    var historyEntry: HistoryEntry?
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad in HistoryDetailsViewController!")
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let label = UILabel(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        // TODO teach yourself NSLayoutConstraints
        //NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        if let entry = historyEntry{
            self.title = dateFormatter.string(from: entry.date)
            elapsedTimeLabel.text = "\(entry.elapsed)" + " seconds"
            rateLabel.text = "$\(entry.rate)"
            valueLabel.text = "$\(entry.value)"
        }
        
        if let val = passedData{
            //self.title = val
            label.text = val
        }
        else{
            //self.title = "No value was passed"
            label.text = "No value was passed"
        }
        //self.view.addSubview(label)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
