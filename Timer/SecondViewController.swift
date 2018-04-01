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
    let myarray = ["item1", "item2", "item3"]
    var timeEntries = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        cell.textLabel?.text = "\(timeEntries[indexPath.row].value(forKey: "value") as! Double)"
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
    
    
}


