//
//  TimeEntry+CoreDataProperties.swift
//  Timer
//
//  Created by Stephen Kim on 5/12/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//
//

import Foundation
import CoreData


extension TimeEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeEntry> {
        return NSFetchRequest<TimeEntry>(entityName: "TimeEntry")
    }

    @NSManaged public var comment: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var elapsed: Int64
    @NSManaged public var rate: Double
    @NSManaged public var value: Double
    
    /**
     * Transient CoreData attribute
     *
     * used to sort table view section by MM/dd/yyyy order
     */
    @objc var section: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date! as Date)
    }

}
