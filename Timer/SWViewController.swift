//
//  SWViewController.swift
//  Timer
//
//  Created by Stephen Kim on 1/23/17.
//  Copyright © 2017 Stephen Kim. All rights reserved.
//

import UIKit

class SWViewController: UIViewController {

    var startTime = TimeInterval();
    var timer = Timer()
    var rate = 18.5
    static let zero = "00:00:00:00"
    
    @IBOutlet var displayTimeLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    
    @IBAction func setRate(sender: AnyObject){
        let alert = UIAlertController(title: "Set a rate", message: "What do you want the new rate to be?", preferredStyle: .alert)
        alert.addTextField { (textField) in
            //textField.text = "default text"
            textField.keyboardType = UIKeyboardType.decimalPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            let textFieldVal: String = (textField?.text)!
            //print(textFieldVal)
            if (textFieldVal.isEmpty){
                print("This string is empty")
            }
            else{
                let val: Double = Double(textFieldVal)!
                self.rate = val 
                print("Text field: \(val)")
            }
        }))
        //alert.addAction{ (textField) in textField.text = "Some default text"
        //}
        self.present(alert, animated: true, completion: nil)
        print("Set button was pressed!")
    }
    
    @IBAction func reset(sender: AnyObject){
        displayTimeLabel.text = SWViewController.zero
        valueLabel.text = "$0.00"
    }
    
    @IBAction func rateButtonPressed(sender: AnyObject){
        let alert = UIAlertController(title: "Current Rate", message: "\(rate)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title:"Okay", style: .default))
        self.present(alert, animated: true, completion:nil)
    }
    
    @IBAction func start(sender: AnyObject){
        
        if !timer.isValid{
            let aSelector : Selector = #selector(SWViewController.updateTime)
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: aSelector, userInfo: nil, repeats: true)
            startTime = NSDate.timeIntervalSinceReferenceDate
        }
        
    }
    
    @IBAction func stop(sender: AnyObject){
        timer.invalidate()
        //timer == nil
    }
    
    func updateTime(){
        var total = 0.0
        var tmprate = rate
        let currentTime = NSDate.timeIntervalSinceReferenceDate
        
        var elapsedTime: TimeInterval = currentTime - startTime
        
        let hours = UInt8(elapsedTime/(60*60))
        total = total + (Double(hours)*tmprate)
        tmprate = tmprate/60.0
        
        elapsedTime -= (TimeInterval(hours) * 60*60)
        
        let minutes = UInt8(elapsedTime/60.0)
        total = total + (Double(minutes)*tmprate)
        tmprate = tmprate/60.0
        
        
        elapsedTime -= (TimeInterval(minutes) * 60)
        
        let seconds = UInt8(elapsedTime)
        total = total + (Double(seconds)*tmprate)
        tmprate = tmprate/100.0
        
        elapsedTime -= TimeInterval(seconds)
        
        let fraction = UInt8(elapsedTime * 100)
        total = total + (Double(fraction)*tmprate)
        
        
        let strHours = String(format: "%02d", hours)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strFraction = String(format: "%02d", fraction)
        let strVal = String(format: "%2.2f", total)
        
        displayTimeLabel.text = "\(strHours):\(strMinutes):\(strSeconds):\(strFraction)"
        valueLabel.text = "$\(strVal)"
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
