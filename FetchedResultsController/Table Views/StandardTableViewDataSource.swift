//
//  StandardTableViewDataSource.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/17/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class StandardTableViewDataSource: NSObject {
    
    
    // MARK: - Vars/Lazy Vars
    
    weak var tableView: UITableView?
    
    var managedObjectContext: NSManagedObjectContext
    
    var fetchedResultsController: NSFetchedResultsController<Reservation>
    
    
    // MARK: - Static Functions
    
    private static func sortDescriptors(for strategy: SortStrategy) -> [NSSortDescriptor] {
        switch strategy {
        case .name:
            return [
                NSSortDescriptor(key: #keyPath(Reservation.sectionID), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.section), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.displayName), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.scheduledAt), ascending: true)
            ]
        case .time:
            return [
                NSSortDescriptor(key: #keyPath(Reservation.sectionID), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.section), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.scheduledAt), ascending: true),
                NSSortDescriptor(key: #keyPath(Reservation.displayName), ascending: true)
            ]
        }
    }
    
    private static func createFetchedResultsController(context: NSManagedObjectContext) -> NSFetchedResultsController<Reservation> {
        let fetchRequest: NSFetchRequest<Reservation> = Reservation.fetchRequest()
        fetchRequest.sortDescriptors = StandardTableViewDataSource.sortDescriptors(for: .name)
        
        fetchRequest.predicate = NSPredicate(
            format: "%K > %@ AND %K < %@",
            #keyPath(Reservation.scheduledAt), Date().startOfDay as NSDate,
            #keyPath(Reservation.scheduledAt), Date().endOfDay as NSDate
        )
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: #keyPath(Reservation.sectionID),
            cacheName: nil
        )
        
        return fetchedResultsController
    }
    
    
    // MARK: - Init/deinit
    
    init(table: UITableView, context: NSManagedObjectContext) {
        tableView = table
        managedObjectContext = context
        fetchedResultsController = StandardTableViewDataSource.createFetchedResultsController(context: context)
        super.init()
        
        fetchedResultsController.delegate = self
        fetch()
    }
    
    
    // MARK: - Private Functions
    
    private func fetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Fetched results controller fetch failed.")
        }
    }
    
    private func resort(for strategy: SortStrategy) {
        fetchedResultsController.fetchRequest.sortDescriptors = StandardTableViewDataSource.sortDescriptors(for: strategy)
        fetch()
        
        guard let tableView = tableView else {
            return
        }
        
        // Animate reload
        tableView.reloadSections(IndexSet(integersIn: 0..<numberOfSections(in: tableView)), with: .fade)
    }
    
    
}


extension StandardTableViewDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReservationCell", for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        let reservation = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = reservation.displayName
        cell.detailTextLabel?.text = DateFormatter.shared.string(from: reservation.scheduledAt! as Date)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionID = Int(fetchedResultsController.sections?[section].name ?? "") else {
            return nil
        }
        
        return Reservation.section(for: sectionID)
    }
    
}


extension StandardTableViewDataSource: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            
        // Insert
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView?.insertRows(at: [newIndexPath], with: .fade)
            }
        
        // Delete
        case .delete:
            if let indexPath = indexPath {
                tableView?.deleteRows(at: [indexPath], with: .fade)
            }
            
        // Update
        case .update:
            if let indexPath = indexPath,
                let cell = tableView?.cellForRow(at: indexPath) {
                configureCell(cell: cell, indexPath: indexPath)
            }
        
        // Move
        case .move:
            if let indexPath = indexPath {
                tableView?.deleteRows(at: [indexPath], with: .fade)
            }
            if let newIndexPath = newIndexPath {
                tableView?.insertRows(at: [newIndexPath], with: .fade)
            }
            
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            
        // Insert
        case .insert:
            tableView?.insertSections(IndexSet([sectionIndex]), with: .fade)
            
        // Delete
        case .delete:
            tableView?.deleteSections(IndexSet([sectionIndex]), with: .fade)
        
        default: break
            
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ControllerDidChangeContent"), object: self)
    }
    
}


extension StandardTableViewDataSource: SortStrategyDelegate {
    
    func sortStrategyChanged(to strategy: SortStrategy) {
        resort(for: strategy)
    }
    
}
