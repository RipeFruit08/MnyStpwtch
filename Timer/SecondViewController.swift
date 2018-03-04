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
    var moneyarr = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moneyarr.removeAll()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeEntry")
        let fetchedData = appDelegate.getData(request: request)
        for data in fetchedData as! [NSManagedObject]{
            print(data.value(forKey: "value") as! Double)
            moneyarr.append(data.value(forKey: "value") as! Double)
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
        return moneyarr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        cell.textLabel?.text = "\(moneyarr[indexPath.row])"
        return cell
    }
    
    
}


