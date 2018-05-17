//
//  HistoryEntry.swift
//  Timer
//
//  Created by Stephen Kim on 4/3/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import Foundation

class HistoryEntry{
    
    //MARK: Properties
    var date: Date
    var elapsed: Int // seconds
    var rate: Double
    var value: Double
    var comment: String?
    
    //MARK: Initialization
    init(date: Date, elapsed: Int, rate: Double, value: Double, comment: String?) {
        // TODO needs validation?
        self.date = date
        self.elapsed = elapsed
        self.rate = rate
        self.value = value
        self.comment = comment
    }
}
