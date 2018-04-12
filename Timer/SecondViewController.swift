//
//  SecondViewController.swift
//  example
//
//  Created by Stephen Kim on 2/23/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import UIKit
import CoreData

class SecondViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    
    @IBOutlet var tableview: UITableView!
    var DarkisOn: Bool?
    let userDefaults = UserDefaults.standard
    let myarray = ["item1", "item2", "item3"]
    var timeEntries = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add Observers
        NotificationCenter.default.addObserver(self, selector: #selector(darkModeEnabled(_:)), name: .darkModeEnabled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(darkModeDisabled(_:)), name: .darkModeDisabled, object: nil)
        applyTheme()
        // Do any additional setup after loading the view, typically from a nib.
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: investigate if this code should be moved into viewDidLoad
        timeEntries.removeAll()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeEntry")
        let fetchedData = appDelegate.getData(request: request)
        for data in fetchedData as! [NSManagedObject]{
            timeEntries.append(data)
            //print(data.value(forKey: "value") as! Double)
        }
        tableview.reloadData()
        print("viewDidAppear")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func darkModeEnabled(_ notification: Notification) {
        // Write your dark mode code here
        print("darkModeEnabled code")
        applyDarkMode()
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
        tableview.backgroundColor = UIColor.black
        // https://stackoverflow.com/questions/25585543/how-to-change-the-text-color-of-all-text-in-uiview
        // updating color of all labels in view
        // TODO make function to change all UILabels to a color
    }
    
    private func applyLightMode(){
        self.view.backgroundColor = UIColor.white
        tableview.backgroundColor = UIColor.white
        // why didnt these work?
        //UITableViewCell.appearance().textLabel?.textColor = UIColor.blue
        //UITableViewCell.appearance().backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        cell.textLabel?.text = "\(timeEntries[indexPath.row].value(forKey: "value") as! Double)"
        // TODO THIS IS A TERRIBLE HACK!!! DON"T DO THIS
        DarkisOn = userDefaults.bool(forKey: "DarkDefault")
        if let mode = DarkisOn{
            if mode{
                cell.textLabel?.textColor = UIColor.white
                cell.backgroundColor = UIColor.black
            } else{
                cell.textLabel?.textColor = UIColor.black
                cell.backgroundColor = UIColor.clear
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if ( editingStyle == UITableViewCellEditingStyle.delete){
            print("put code for delete action here")
            let alert = UIAlertController(title: "Delete", message: "Do you want to delete this entry?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {_ in
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let toDelete = self.timeEntries[indexPath.row]
                do{
                    context.delete(toDelete);
                    try context.save()
                    self.timeEntries.remove(at: indexPath.row)
                    self.tableview.reloadData()
                } catch {
                    print("Failed saving")
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("this cell was tapped")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .darkModeEnabled, object: nil)
        NotificationCenter.default.removeObserver(self, name: .darkModeDisabled, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "historyDetailsSegue"{
            print("this code got called!")
            if let selectedIndex = tableview.indexPathForSelectedRow?.row{
                let selected = timeEntries[selectedIndex]
                let date = selected.value(forKey: "date") as! Date
                let elapsed = selected.value(forKey: "elapsed") as! Int
                let rate = selected.value(forKey: "rate") as! Double
                let value = selected.value(forKey: "value") as! Double
                let comment = selected.value(forKey: "comment") as! String?
                let entry = HistoryEntry(date: date, elapsed: elapsed, rate: rate, value: value, comment: comment)
                let navController = segue.destination as! HistoryDetailsViewController
                navController.passedData = "fuck";
                navController.historyEntry = entry;
            }
            

        }
    }
    
    
}


