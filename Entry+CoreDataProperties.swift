//
//  Entry+CoreDataProperties.swift
//  
//
//  Created by Robert Mathews on 11/1/17.
//
//

import Foundation
import CoreData


extension Entry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry")
    }

    @NSManaged public var completedTaskIds: [Double]
    @NSManaged public var createdTaskIds: [Double]
    @NSManaged public var entryDate: NSDate?

}
