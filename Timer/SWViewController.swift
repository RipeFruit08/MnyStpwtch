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
    var firstRun = true;
    static let zero = "00:00:00:00"
    
    
    @IBOutlet var displayTimeLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    
    /**
     Sets rate value that is being used to calculate money earned
    */
    @IBAction func setRate(sender: AnyObject){
        // the pop-up dialog box
        let alert = UIAlertController(title: "Set a rate", message: "What do you want the new rate to be?", preferredStyle: .alert)
        // the textbox for new rate value
        alert.addTextField { (textField) in
            //textField.text = "default text"
            textField.text = String(self.rate)
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
                self.rateLabel.text = "Current Rate: \(val)"
                print("Text field: \(val)")
            }
        }))
        //alert.addAction{ (textField) in textField.text = "Some default text"
        //}
        self.present(alert, animated: true, completion: nil)
        print("Set button was pressed!")
    }
    
    @IBAction func reset(sender: AnyObject){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "TimeEntry", in: context)
        let newEntry = NSManagedObject(entity: entity!, insertInto: context)
        newEntry.setValue(Date(), forKey: "date")
        newEntry.setValue(Int64(timeElapsed), forKey: "elapsed")
        newEntry.setValue(rate, forKey: "rate")
        newEntry.setValue(Double(earnings).rounded(toPlaces: 2), forKey: "value")
        do{
            try context.save()
        } catch {
            print("Failed saving")
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeEntry")
        //request.predicate = NSPredicate(format: "age = %@", "12")
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "value") as! Double)
            }
            
        } catch {
            
            print("Failed")
        }
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
            print("starting the timer")
            let aSelector : Selector = #selector(SWViewController.updateTime)
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: aSelector, userInfo: nil, repeats: true)
            if bgBool{
                bgBool = false
                
            }
            else{
                startTime = NSDate.timeIntervalSinceReferenceDate
            }
            // toggles running flag
            running = true
        }
        
    }
    
    @IBAction func stop(sender: AnyObject){
        timer.invalidate()
        if running{
            running = false;
        }
        //timer == nil
    }
    
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
        valueLabel.text = "$\(strVal)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app = UIApplication.shared
        
        // Register for the applicationWillResignActive anywhere in your app
        NotificationCenter.default.addObserver(self, selector: #selector(SWViewController.applicationWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: app)

        NotificationCenter.default.addObserver(self, selector: #selector(SWViewController.applicationDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: app)
        
        rateLabel.text = "Current Rate: \(rate)"
        // Do any additional setup after loading the view.
    }
    
    @objc func applicationWillResignActive(notification: NSNotification){
        print("application went into the background")
        bgTimeStamp = Date()
        if running{
            stop(sender: self)
            bgBool = true
        }
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification){
        print("application came into the foreground")
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
        start(sender: self)
        // TODO: update time to include 1/100th of second accuracy
        //var diff = endTimeStamp - bgTimeStamp
        
    }
    
    /*
     yeah... this didn't work :/
     TODO figure this out
    static func +(_ lhs: DateComponents, _ rhs: DateComponents) -> DateComponents{
        return combineComponents(lhs, rhs)
    }
    
    static func -(_ lhs: DateComponents, _ rhs:DateComponents) -> DateComponents{
        return combineComponents(lhs, rhs)
    }
    
    static func combineComponents(_ lhs: DateComponents,
                           _ rhs: DateComponents,
                           multiplier: Int = 1) -> DateComponents{
        var result = DateComponents()
        result.second     = (lhs.second     ?? 0) + (rhs.second     ?? 0) * multiplier
        result.minute     = (lhs.minute     ?? 0) + (rhs.minute     ?? 0) * multiplier
        result.hour       = (lhs.hour       ?? 0) + (rhs.hour       ?? 0) * multiplier
        result.day        = (lhs.day        ?? 0) + (rhs.day        ?? 0) * multiplier
        result.weekOfYear = (lhs.weekOfYear ?? 0) + (rhs.weekOfYear ?? 0) * multiplier
        result.month      = (lhs.month      ?? 0) + (rhs.month      ?? 0) * multiplier
        result.year       = (lhs.year       ?? 0) + (rhs.year       ?? 0) * multiplier
        return result
    }
 
    */

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
