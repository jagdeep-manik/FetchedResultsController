//
//  EntityTableController.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/19/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//

import ReactiveSwift
import Foundation
import CoreData

/// Models a change to an individual entity for a table view to respond to.
enum EntityTableControllerChange {
    
    case insert(indexPath: IndexPath)
    
    case delete(indexPath: IndexPath)
    
    case move(fromIndexPath: IndexPath, toIndexPath: IndexPath)
    
    case update(indexPath: IndexPath)
    
}

/// Models a change to an individual table section for a table view to respond to.
enum EntityTableControllerSectionChange {
    
    case insert(index: Int)
    
    case delete(index: Int)
    
}


/// Generic protocol modeled after NSFetchedResultsControllerDelegate
protocol EntityTableControllerDelegate: class {
    
    func controllerWillChangeContent<Entity: NSManagedObject>(_ controller: EntityTableController<Entity>)
    
    func controller<Entity: NSManagedObject>(_ controller: EntityTableController<Entity>,
                                             didChange anObject: Entity,
                                             change: EntityTableControllerChange)
    
    func controller<Entity: NSManagedObject>(_ controller: EntityTableController<Entity>,
                                             didChange section: EntityTableSection<Entity>,
                                             change: EntityTableControllerSectionChange)
    
    func controllerDidChangeContent<Entity: NSManagedObject>(_ controller: EntityTableController<Entity>)
    
}


class EntityTableController<Entity: NSManagedObject> {
    
    // MARK: - Vars/Lazy Vars
    
    let sections: MutableProperty<[EntityTableSection<Entity>]> = MutableProperty([])
    
    var fetchRequest: NSFetchRequest<Entity>
    
    var context: NSManagedObjectContext {
        didSet {
            registerForManagedObjectContextChanges()
            
            // TODO: reload
        }
    }
    
    var numberOfSections: Int {
        return tree.visibleSections.count
    }
    
    var fetchedObjects: [Entity] {
        return tree.visibleSections.reduce([], { (objects, section) -> [Entity] in
            return objects + section.fetchedObjects
        })
    }
    
    weak var delegate: EntityTableControllerDelegate?
    
    
    // MARK: - Private Vars
    
    private var tree: EntityTableTree<Entity>
    
    
    // MARK: - Init/deinit
    
    init(fetchRequest: NSFetchRequest<Entity>, context: NSManagedObjectContext) {
        self.context = context
        self.fetchRequest = fetchRequest
        self.tree = EntityTableTree(sections: sections.value)
        
        sections.producer.startWithValues { [weak self] sections in
            self?.tree = EntityTableTree(sections: sections)
        }
        
        registerForManagedObjectContextChanges()
    }
    
    
    // MARK: - Notifications
    
    private func registerForManagedObjectContextChanges() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectsDidChange(_:)),
            name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: context
        )
    }
    
    
    // MARK: - Public Functions
    
    func numberOfRows(for section: Int) -> Int {
        return tree.visibleSections[section].fetchedObjects.count
    }
    
    func object(at indexPath: IndexPath) -> Entity {
        return tree.object(at: indexPath)
    }
    
    func title(forSection index: Int) -> String {
        return tree.visibleSections[index].name
    }
    
    func performFetch() {
        context.performAndWait {
            if let fetchResults = try? context.fetch(fetchRequest) {
                sections.value.forEach { $0.reset() }
                _ = tree.processChangedObjects(objects: Set(fetchResults))
            }
        }
    }
    
    
    // MARK: - Private Functions
    
    @objc private func managedObjectsDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        let inserted = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.compactMap { $0 as? Entity } ?? []
        let updated = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.compactMap { $0 as? Entity } ?? []
        let deleted = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.compactMap { $0 as? Entity } ?? []
        
        // Combine into a single set
        let allObjects = Set<Entity>().union(inserted).union(updated).union(deleted).filter { fetchRequest.predicate?.evaluate(with: $0) ?? false }
        
        // Quit early if not our observed type
        guard allObjects.count > 0 else {
            return
        }
        
        // Cache current section counts
        var cachedSectionCounts = [EntityTableSection<Entity>: (index: Int, count: Int)]()
        
        tree.visibleSections.enumerated().forEach {
            cachedSectionCounts[$0.element] = (index: $0.offset, count: $0.element.fetchedObjects.count)
        }
        
        // Notify delegate for batch changes
        delegate?.controllerWillChangeContent(self)
        
        // Process the changed objects
        let changes = tree.processChangedObjects(objects: allObjects)
        
        // Notify delegate for deleted sections (N -> 0 count after the processing)
        cachedSectionCounts
            .filter { $0.value.count > 0 }
            .filter { $0.key.fetchedObjects.count == 0 }
            .forEach {
                delegate?.controller(self,
                                     didChange: $0.key,
                                     change: .delete(index: $0.value.index))
        }
        
        // Notify delegate for inserted sections (0 -> N count after the processing)
        tree.visibleSections.enumerated()
            .filter { cachedSectionCounts[$0.element] == nil }
            .filter { $0.element.fetchedObjects.count > 0 }
            .forEach {
                delegate?.controller(self,
                                     didChange: $0.element,
                                     change: .insert(index: $0.offset))
        }
        
        // Notify delegate of individual object changes
        changes.forEach { (change) in
            
            // delete
            if let previousSectionInfo = change.previousSectionInfo,
                change.newSectionInfo == nil {
                delegate?.controller(self,
                                     didChange: change.entity,
                                     change: .delete(indexPath: previousSectionInfo.indexPath))
                
            // insert
            } else if let newSectionInfo = change.newSectionInfo,
                change.previousSectionInfo == nil {
                delegate?.controller(self,
                                     didChange: change.entity,
                                     change: .insert(indexPath: newSectionInfo.indexPath))
                
            // update or move
            } else if let previousSectionInfo = change.previousSectionInfo,
                let newSectionInfo = change.newSectionInfo {
                
                // update
                if  previousSectionInfo.section == newSectionInfo.section,
                    previousSectionInfo.indexPath == newSectionInfo.indexPath {
                    delegate?.controller(self,
                                         didChange: change.entity,
                                         change: .update(indexPath: newSectionInfo.indexPath))
                
                // move
                } else {
                    delegate?.controller(self,
                                         didChange: change.entity,
                                         change: .move(fromIndexPath: previousSectionInfo.indexPath,
                                                       toIndexPath: newSectionInfo.indexPath))
                }
                
            }
            
        }
        
        // Done
        delegate?.controllerDidChangeContent(self)
    }
    
    
}
