//
//  Reservation+CoreDataClass.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/17/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Reservation)
public class Reservation: NSManagedObject {

    @discardableResult
    static func generateRandom(in context: NSManagedObjectContext) -> Reservation? {
        guard let reservation = NSEntityDescription.insertNewObject(forEntityName: "Reservation", into: context) as? Reservation else {
            print("Error creating reservation.")
            return nil
        }
        
        reservation.displayName = Fakie.randomName()
        reservation.scheduledAt = Date(timeInterval: TimeInterval(Int.random(in: 0...1000)), since: Date()) as NSDate
        reservation.reservationID = UUID().uuidString
        reservation.setSection(section: Fakie.randomSection())
        return reservation
    }
    
    static func deleteAll(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Reservation.fetchRequest()
        fetchRequest.predicate = NSPredicate(value: true)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
        } catch {
            print("Failed to delete reservations.")
        }
    }
    
    static func findAll(in context: NSManagedObjectContext) -> [Reservation] {
        let fetchRequest: NSFetchRequest<Reservation> = Reservation.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching from context: \(error)")
        }
        
        return []
    }
    
    static func sectionID(for section: String) -> Int {
        switch section {
        case "Waitlist":
            return 0
        case "Reservations":
            return 1
        case "Seated":
            return 2
        case "Finished":
            return 3
        case "Removed":
            return 4
        default:
            return 0
        }
    }
    
    static func section(for sectionID: Int) -> String {
        switch sectionID {
        case 0:
            return "Waitlist"
        case 1:
            return "Reservations"
        case 2:
            return "Seated"
        case 3:
            return "Finished"
        case 4:
            return "Removed"
        default:
            return "Waitlist"
        }
    }
    
    func setSection(section: String) {
        self.section = section
        self.sectionID = NSNumber(integerLiteral: Reservation.sectionID(for: section))
    }
    
}
