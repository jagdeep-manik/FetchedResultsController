//
//  Reservation+CoreDataProperties.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/17/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//
//

import Foundation
import CoreData


extension Reservation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reservation> {
        return NSFetchRequest<Reservation>(entityName: "Reservation")
    }

    @NSManaged public var reservationID: String?
    @NSManaged public var scheduledAt: NSDate?
    @NSManaged public var displayName: String?
    @NSManaged public var section: String?
    @NSManaged public var sectionID: NSNumber?

}
