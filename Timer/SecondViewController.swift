//
//  SecondViewController.swift
//  example
//
//  Created by Stephen Kim on 2/23/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import UIKit
import CoreData

class SecondViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate{
    
    
    @IBOutlet var tableview: UITableView!
    var NSFRController: NSFetchedResultsController<TimeEntry>?
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "rate", ascending: false)]
        NSFRController = (NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "section", cacheName: nil) as! NSFetchedResultsController<TimeEntry>)
        NSFRController?.delegate = self
        do {
            try NSFRController?.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
        //NSFRController?.sectionNameKeyPath
        // Do any additional setup after loading the view, typically from a nib.
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: investigate if this code should be moved into viewDidLoad
        timeEntries.removeAll()
        
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let context = appDelegate.persistentContainer.viewContext
//        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeEntry")
//        request.sortDescriptors = [NSSortDescriptor(key: "rate", ascending: false)]
//        NSFRController = (NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil) as! NSFetchedResultsController<NSManagedObject>)
//        do {
//            try NSFRController?.performFetch()
//        } catch {
//            fatalError("Failed to fetch entities: \(error)")
//        }
        //let fetchedData = appDelegate.getData(request: request)
        //for data in fetchedData as! [NSManagedObject]{
        //    timeEntries.append(data)
            //print(data.value(forKey: "value") as! Double)
        //}
        //tableview.reloadData()
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
        let cellAppearance: HistoryTableViewCell = HistoryTableViewCell.appearance()
        //cellAppearance.backgroundColor = UIColor.clear
        //cellAppearance.bgColor = UIColor.clear
        //cellAppearance.setBackground(UIColor.black) // why doesn't this work?
        cellAppearance.textLabel?.textColor = UIColor.white
        // why didnt these work?
        //UITableViewCell.appearance().textLabel?.textColor = UIColor.blue
        //UITableViewCell.appearance().backgroundColor = UIColor.clear
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let frc = NSFRController{
            print("non zero number of sections!!!: \(frc.sections!.count)")
            return frc.sections!.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return timeEntries.count
        guard let sections = self.NSFRController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath) as! HistoryTableViewCell
        guard let myObject = self.NSFRController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        // Configure the cell with data from the managed object.
        cell.textLabel?.text = "\(myObject.value(forKey: "value") as! Double)"

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = NSFRController?.sections?[section] else {
            return nil
        }
        return sectionInfo.name
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return NSFRController?.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard let result = NSFRController?.section(forSectionIndexTitle: title, at: index) else {
            fatalError("Unable to locate section for \(title) at index: \(index)")
        }
        return result
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableview.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type{
        case .insert:
            tableview.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableview.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            print("move occurred! handle this shit")
        case .update:
            print("update occurred! handle this shit")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type{
        case .insert:
            tableview.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableview.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableview.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableview.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableview.endUpdates()
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
                guard let toDelete = self.NSFRController?.object(at: indexPath) else {
                    fatalError("DELETEING: Attempt to configure cell without a managed object")
                }
                do{
                    context.delete(toDelete);
                    try context.save()
                } catch {
                    print("Failed saving")
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableview.deselectRow(at: indexPath, animated: true)
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .darkModeEnabled, object: nil)
        NotificationCenter.default.removeObserver(self, name: .darkModeDisabled, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "historyDetailsSegue"{
            print("historyDetailsSegue")
            guard let selected = self.NSFRController?.object(at: tableview.indexPathForSelectedRow!) else {
                fatalError("Attempt to configure cell without a managed object")
            }
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


