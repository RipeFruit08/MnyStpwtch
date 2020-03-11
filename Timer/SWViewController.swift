//
//  SWViewController.swift
//  Timer
//
//  Created by Stephen Kim on 1/23/17.
//  Copyright © 2017 Stephen Kim. All rights reserved.
//

import UIKit
import CoreData

class SWViewController: UIViewController {

    var startTime = TimeInterval();
    var timer = Timer()
    var rate = 19.0
    var running = false;
    var bgTimeStamp = Date()
    var bgBool = false
    var earnings = 0.0
    var timeElapsed: TimeInterval = NSDate.timeIntervalSinceReferenceDate
    var firstRun = true
    let userDefaults = UserDefaults.standard
    static let zero = "00:00:00:00"
    
    
    @IBOutlet var displayTimeLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    
    @IBOutlet var saveButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    
    /**
     Notification responding to changing user rate
     */
    @objc private func userRateChanged(_ notification: Notification){
        // grabs updated userDefault values and updates displayed rate
        let newRate: Double = userDefaults.double(forKey: "UserRate")
        self.rate = newRate
        self.rateLabel.text = "Current Rate: \(newRate)"
    }
    
    
    @IBAction func save(_ sender: Any) {
        if (!running){
            let alert = UIAlertController(title: "Comment?", message: "You can leave a comment here", preferredStyle: .alert)
            // the textbox for new rate value
            alert.addTextField { (textField) in
                textField.keyboardType = UIKeyboardType.default
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                let comment = textField?.text
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "TimeEntry", in: context)
                let newEntry = NSManagedObject(entity: entity!, insertInto: context)
                newEntry.setValue(Date(), forKey: "date")
                newEntry.setValue(Int64(self.timeElapsed), forKey: "elapsed")
                newEntry.setValue(self.rate, forKey: "rate")
                newEntry.setValue(Double(self.earnings).rounded(toPlaces: 2), forKey: "value")
                newEntry.setValue(comment, forKey: "comment")
                do{
                    try context.save()
                } catch {
                    print("Failed saving")
                }
            }))
            self.present(alert, animated: true, completion: nil)
            print("Set button was pressed!")
        }
    }
    @IBAction func reset(sender: AnyObject){
        displayTimeLabel.text = SWViewController.zero
        valueLabel.text = "$0.00"
    }
    
    func startTimer(){
        if !timer.isValid{
            print("startTimer")
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            if bgBool{
                bgBool = false
            }
            else{
                startTime = NSDate.timeIntervalSinceReferenceDate
            }
            running = true
        }
    }
    
    func stopTimer(){
        timer.invalidate()
        running = false
    }
    
    @IBAction func start(sender: AnyObject){
        
        // starts a timer, update text to say stop
        if !running{
            startButton.setTitle("Stop", for: .normal)
            startTimer()
        }
        else{
            startButton.setTitle("Start", for: .normal)
            stopTimer()
        }
        
    }
    
    @IBAction func stop(sender: AnyObject){
        // TODO remove this its corresponding view element
    }
    
    // TODO move this somewhere?
    @objc func updateTime(){
        let currentTime = NSDate.timeIntervalSinceReferenceDate
        calculateEarnings(start: startTime, end: currentTime)
    }
    
    func calculateEarnings(start: TimeInterval, end: TimeInterval){
        var total = 0.0
        var tmprate = rate
        var elapsedTime: TimeInterval = end - start
        timeElapsed = elapsedTime
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
        earnings = total
        displayTimeLabel.text = "\(strHours):\(strMinutes):\(strSeconds):\(strFraction)"
        //displayTimeLabel.sizeToFit();
        valueLabel.text = "$\(strVal)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add Observers
        NotificationCenter.default.addObserver(self, selector: #selector(userRateChanged(_:)), name: .userRateChanged, object: nil)
        
        
        let app = UIApplication.shared
        displayTimeLabel.font = displayTimeLabel.font.monospacedDigitFont;
        
        // Register for the applicationWillResignActive anywhere in your app
        NotificationCenter.default.addObserver(self, selector: #selector(SWViewController.applicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: app)

        NotificationCenter.default.addObserver(self, selector: #selector(SWViewController.applicationDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: app)
        

        // Do any additional setup after loading the view.
    }
    
    @objc func applicationWillResignActive(notification: NSNotification){
        print("application went into the background")
        bgTimeStamp = Date()
        if running{
            stopTimer()
            bgBool = true
        }
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification){
        print("application came into the foreground")
        // when the app first launches it hits applicationDidBecomeActive
        if firstRun{
            firstRun = false
            return
        }
        if !bgBool{
            return
        }
        //bgBool = true
        let endTimeStamp = Date()
        let end = NSDate.timeIntervalSinceReferenceDate
        let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: bgTimeStamp, to: endTimeStamp)
        print(bgTimeStamp)
        print(endTimeStamp)
        print("difference is \(components.hour ?? 0) hours, \(components.minute ?? 0) minutes, \(components.second ?? 0) seconds, and \(components.nanosecond ?? 0) nanoseconds")
        calculateEarnings(start: startTime, end: end)
        startTimer()
        // TODO: update time to include 1/100th of second accuracy
        //var diff = endTimeStamp - bgTimeStamp
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .userRateChanged, object: nil)
    }

    
    // MARK: - Navigation

//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//    }
 

}
