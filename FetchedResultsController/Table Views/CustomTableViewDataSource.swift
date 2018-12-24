//
//  CustomTableViewDataSource.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/20/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CustomTableViewDataSource: NSObject {
    
    
    // MARK: - Vars/Lazy Vars
    
    weak var tableView: UITableView?
    
    var managedObjectContext: NSManagedObjectContext
    
    var entityTableController: EntityTableController<Reservation>
    
    
    // MARK: - Static Functions
    
    private static func sortDescriptors(for strategy: SortStrategy) -> [NSSortDescriptor] {
        switch strategy {
        case .name:
            return [
                NSSortDescriptor(key: #keyPath(Reservation.section), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.displayName), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.scheduledAt), ascending: true)
            ]
        case .time:
            return [
                NSSortDescriptor(key: #keyPath(Reservation.section), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.scheduledAt), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.displayName), ascending: true)
            ]
        }
    }
    
    private static func sections() -> [EntityTableSection<Reservation>] {
        return [
            EntityTableSection<Reservation>(
                name: "Waitlist",
                filter: { return $0.section == "Waitlist" },
                sortDescriptors: CustomTableViewDataSource.sortDescriptors(for: .name)
            ),
            EntityTableSection<Reservation>(
                name: "Reservations",
                filter: { return $0.section == "Reservations" },
                sortDescriptors: CustomTableViewDataSource.sortDescriptors(for: .name)
            ),
            EntityTableSection<Reservation>(
                name: "Seated",
                filter: { return $0.section == "Seated" },
                sortDescriptors: CustomTableViewDataSource.sortDescriptors(for: .name)
            ),
            EntityTableSection<Reservation>(
                name: "Finished",
                filter: { return $0.section == "Finished" },
                sortDescriptors: CustomTableViewDataSource.sortDescriptors(for: .name)
            ),
            EntityTableSection<Reservation>(
                name: "Removed",
                filter: { return $0.section == "Removed" },
                sortDescriptors: CustomTableViewDataSource.sortDescriptors(for: .name)
            )
        ]
    }
    
    private static func createEntityTableController(context: NSManagedObjectContext) -> EntityTableController<Reservation> {
        let fetchRequest: NSFetchRequest<Reservation> = Reservation.fetchRequest()
        fetchRequest.sortDescriptors = CustomTableViewDataSource.sortDescriptors(for: .name)
        
        fetchRequest.predicate = NSPredicate(
            format: "%K > %@ AND %K < %@",
            #keyPath(Reservation.scheduledAt), Date().startOfDay as NSDate,
            #keyPath(Reservation.scheduledAt), Date().endOfDay as NSDate
        )
        
        return EntityTableController(fetchRequest: fetchRequest, context: context)
    }
    
    
    // MARK: - Init/deinit
    
    init(table: UITableView, context: NSManagedObjectContext) {
        tableView = table
        managedObjectContext = context
        entityTableController = CustomTableViewDataSource.createEntityTableController(context: context)
        super.init()
        
        entityTableController.sections.value = CustomTableViewDataSource.sections()
        entityTableController.delegate = self
        
        fetch()
    }
    
    
    // MARK: - Private Functions
    
    private func fetch() {
        entityTableController.performFetch()
    }
    
}


extension CustomTableViewDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return entityTableController.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entityTableController.numberOfRows(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomReservationCell", for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        let reservation = entityTableController.object(at: indexPath)
        cell.textLabel?.text = reservation.displayName
        cell.detailTextLabel?.text = DateFormatter.shared.string(from: reservation.scheduledAt! as Date)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return entityTableController.title(forSection: section)
    }
    
}


extension CustomTableViewDataSource: EntityTableControllerDelegate {
    
    func controllerWillChangeContent<Entity>(_ controller: EntityTableController<Entity>) where Entity : NSManagedObject {
        tableView?.beginUpdates()
    }
    
    func controller<Entity>(_ controller: EntityTableController<Entity>, didChange anObject: Entity, change: EntityTableControllerChange) where Entity : NSManagedObject {
        switch change {
            
        case .insert(let indexPath):
            tableView?.insertRows(at: [indexPath], with: .fade)
            
        case .delete(let indexPath):
            tableView?.deleteRows(at: [indexPath], with: .fade)
        
        case .update(let indexPath):
            if let cell = tableView?.cellForRow(at: indexPath) {
                configureCell(cell: cell, indexPath: indexPath)
            }
        
        case .move(let fromIndexPath, let toIndexPath):
            tableView?.deleteRows(at: [fromIndexPath], with: .fade)
            tableView?.insertRows(at: [toIndexPath], with: .fade)
            
        }
    }
    
    func controller<Entity>(_ controller: EntityTableController<Entity>, didChange section: EntityTableSection<Entity>, change: EntityTableControllerSectionChange) where Entity : NSManagedObject {
        switch change {
            
        case .insert(let index):
            tableView?.insertSections([index], with: .fade)
        
        case .delete(let index):
            tableView?.deleteSections([index], with: .fade)
            
        }
    }
    
    func controllerDidChangeContent<Entity>(_ controller: EntityTableController<Entity>) where Entity : NSManagedObject {
        tableView?.endUpdates()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ControllerDidChangeContent"), object: self)
    }
    
}
