//
//  TaskTableViewCell.swift
//  GoTime
//
//  Created by Robert Mathews on 11/14/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {

   @IBOutlet weak var taskLabel: UILabel!
   @IBOutlet weak var priorityLabel: UILabel!
   
   override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
