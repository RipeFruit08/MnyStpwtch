//
//  SettingsViewController.swift
//  Timer
//
//  Created by Stephen Kim on 4/11/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var darkThemeText: UILabel!
    @IBOutlet var darkThemeToggle: UISwitch!
    @IBOutlet var rateLabel: UILabel!
    @IBOutlet var rateField: UITextField!
    let userDefaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        self.view.addGestureRecognizer(swipeDown)
        rateField.delegate = self
        print("hi?")
        rateField.keyboardType = .decimalPad
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // stuff
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // TODO validate input
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("validating input")
        let textFieldVal: String = (textField.text)!
        if textFieldVal.isEmpty {
            print("this string is empty")
        }
        else {
            let val: Double = Double(textFieldVal)!
            print("new rate is \(val)")
            userDefaults.set(val, forKey: "UserRate")
            // how to pass data through NotificationCenter post
            NotificationCenter.default.post(name: .userRateChanged, object: nil)
        }
    }
    
    // triggered action associated with the toggle switch in the Settings View Controller.
    @IBAction func darkModeSwitched(_ sender: Any) {
        if darkThemeToggle.isOn{
            print("switch toggled on")
        }
        else{
            print("switch toggled off")
        }
    }
    
    @objc
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                print("Swiped right")
            case UISwipeGestureRecognizer.Direction.down:
                rateField.resignFirstResponder()
            case UISwipeGestureRecognizer.Direction.left:
                print("Swiped left")
            case UISwipeGestureRecognizer.Direction.up:
                print("Swiped up")
            default:
                break
            }
        }
    }
    
    deinit {
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

