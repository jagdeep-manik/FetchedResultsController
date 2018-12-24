//
//  EntityTableSection.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/19/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//

import Foundation
import CoreData

class EntityTableSection<Entity: NSManagedObject>: NSObject {
    
    // MARK: - Vars/Lazy Vars
    
    let name: String
    
    let alwaysDisplayed: Bool
    
    let isIncluded: (Entity) -> Bool
    
    var sortDescriptors: [NSSortDescriptor]
    
    var fetchedObjects: [Entity] = []
    
    
    // MARK: - Private Vars
    
    private var stagedEntities = Set<Entity>()
    
    private var unstagedEntities = Set<Entity>()
    
    
    // MARK: - Init/deinit
    
    init(name: String, filter: @escaping (Entity) -> Bool, sortDescriptors: [NSSortDescriptor], alwaysDisplayed: Bool = false) {
        self.name = name
        self.isIncluded = filter
        self.sortDescriptors = sortDescriptors
        self.alwaysDisplayed = alwaysDisplayed
    }
    
    
    // MARK: - Public Functions
    
    func stage(entity: Entity) {
        stagedEntities.insert(entity)
        unstagedEntities.remove(entity)
    }
    
    func unstage(entity: Entity) {
        unstagedEntities.insert(entity)
        stagedEntities.remove(entity)
    }
    
    func commit() {
        let unchangedObjects = fetchedObjects.filter {
            unstagedEntities.contains($0) == false && stagedEntities.contains($0) == false
        }
        
        let unsortedObjects = unchangedObjects + Array(stagedEntities)
        
        // sort
        fetchedObjects = (unsortedObjects as NSArray).sortedArray(using: sortDescriptors) as? [Entity] ?? []
        
        // clean up
        unstagedEntities.removeAll()
        stagedEntities.removeAll()
    }
    
    func reset() {
        fetchedObjects = []
        stagedEntities.removeAll()
        unstagedEntities.removeAll()
    }
    
    func index(of entity: Entity) -> Int? {
        return fetchedObjects.firstIndex(of: entity)
    }
    
}
