//
//  SettingsViewController.swift
//  Timer
//
//  Created by Stephen Kim on 4/11/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet var darkThemeText: UILabel!
    @IBOutlet var darkThemeToggle: UISwitch!
    var DarkisOn: Bool?
    let userDefaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add Observers
        NotificationCenter.default.addObserver(self, selector: #selector(darkModeEnabled(_:)), name: .darkModeEnabled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(darkModeDisabled(_:)), name: .darkModeDisabled, object: nil)
        
        print("hi?")
        applyTheme()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // stuff
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func darkModeSwitched(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if darkThemeToggle.isOn{
            //enable dark mode
            DarkisOn = true
            userDefaults.set(true, forKey: "DarkDefault")
            userDefaults.set(false, forKey: "LightDefault")
            // update nav bar color for future views but still need to update current view
            appDelegate.applyTheme()
            self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.barTintColor = UIColor.black
            self.navigationController?.navigationBar.shadowImage = UIColor.white.asImage(width: 0.25, height: 0.25)
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
            self.tabBarController?.tabBar.barTintColor = UIColor.black
            NotificationCenter.default.post(name: .darkModeEnabled, object: nil)
        }
        else{
            //enable light mode
            DarkisOn = false
            userDefaults.set(false, forKey: "DarkDefault")
            userDefaults.set(true, forKey: "LightDefault")
            appDelegate.applyTheme()
            self.navigationController?.navigationBar.tintColor = UIColor.black
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.barTintColor = UIColor.white
            self.navigationController?.navigationBar.shadowImage = UIColor.black.asImage(width: 0.25, height: 0.25)
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.black]
            self.tabBarController?.tabBar.barTintColor = UIColor.white
            NotificationCenter.default.post(name: .darkModeDisabled, object: nil)
        }
    }
    
    @objc private func darkModeEnabled(_ notification: Notification) {
        // Write your dark mode code here
        print("darkModeEnabled code")
        applyDarkMode()
        
        //stopButton.setTitle("yo", for: .normal)
    }
    
    @objc private func darkModeDisabled(_ notification: Notification) {
        // Write your non-dark mode code here
        print("darkModeDisabled code")
        applyLightMode()
    }
    
    // am i doing this right? ¯\_(ツ)_/¯
    private func applyTheme(){
        // TODO what if no key is set? it will return false
        // that would mean default implementation of the app would be to have a light theme
        DarkisOn = userDefaults.bool(forKey: "DarkDefault")
        if let mode = DarkisOn{
            if mode{
                applyDarkMode()
            }
            else{
                applyLightMode()
            }
        }
    }
    
    private func applyDarkMode(){
        self.view.backgroundColor = UIColor.black
        // https://stackoverflow.com/questions/25585543/how-to-change-the-text-color-of-all-text-in-uiview
        // updating color of all labels in view
        // TODO make function to change all UILabels to a color
        darkThemeText.textColor = UIColor.white
        darkThemeToggle.setOn(true, animated: true)
    }
    
    private func applyLightMode(){
        self.view.backgroundColor = UIColor.white
        darkThemeText.textColor = UIColor.black
        darkThemeToggle.setOn(false, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .darkModeEnabled, object: nil)
        NotificationCenter.default.removeObserver(self, name: .darkModeDisabled, object: nil)
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

