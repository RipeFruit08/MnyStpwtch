//
//  HistoryTableViewCell.swift
//  Timer
//
//  Created by Stephen Kim on 5/16/18.
//  Copyright © 2018 Stephen Kim. All rights reserved.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setBackground(_ color: UIColor){
        self.backgroundColor = color
    }

}
