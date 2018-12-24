//
//  EntityTableTree.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/19/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//

import ReactiveSwift
import Foundation
import CoreData


class EntityTableTree<Entity: NSManagedObject> {
    
    /// Represents section and index path information for an entity (at that point in time).
    typealias EntitySectionInfo = (section: EntityTableSection<Entity>, indexPath: IndexPath)
    
    
    /// Models an individual change to an observed object.
    class EntityTableTreeChange {
        
        let entity: Entity
        
        var previousSectionInfo: EntitySectionInfo?
        
        var newSectionInfo: EntitySectionInfo?
        
        init(entity: Entity) {
            self.entity = entity
        }
        
    }
    
    
    // MARK: - Vars/Lazy Vars
    
    let sections: [EntityTableSection<Entity>]
    
    var visibleSections: [EntityTableSection<Entity>] {
        return sections.filter { $0.alwaysDisplayed || $0.fetchedObjects.count > 0 }
    }
    
    
    // MARK: - Init/deinit
    
    init(sections: [EntityTableSection<Entity>]) {
        self.sections = sections
    }
    
    
    // MARK: - Public Functions
    
    func processChangedObjects(objects: Set<Entity>) -> [EntityTableTreeChange] {
        var changes = [Entity: EntityTableTreeChange]()
        
        // Prepare to track entity changes
        objects.forEach { changes[$0] = EntityTableTreeChange(entity: $0) }
        
        // Track current section info for each entity and unstage that entity
        sectionInfoForChangedObjects().forEach { (entity, sectionInfo) in
            changes[entity]?.previousSectionInfo = sectionInfo
            sectionInfo.section.unstage(entity: entity)
        }
        
        // Stage entities into their new section
        objects.forEach { section(for: $0)?.stage(entity: $0) }
        
        // Resolve changes to each section (+ sort)
        sections.forEach { $0.commit() }
        
        // Track new section info
        sectionInfoForChangedObjects().forEach { (entity, sectionInfo) in
            changes[entity]?.newSectionInfo = sectionInfo
        }
        
        return Array(changes.values)
    }
    
    func object(at indexPath: IndexPath) -> Entity {
        return visibleSections[indexPath.section].fetchedObjects[indexPath.row]
    }
    
    func indexPath(for object: Entity) -> IndexPath? {
        for (offset, section) in visibleSections.enumerated() {
            if let row = section.index(of: object) {
                return IndexPath(row: row, section: offset)
            }
        }
        
        return nil
    }
    
    
    // MARK: - Private Functions
    
    private func sectionInfoForChangedObjects() -> [Entity: EntitySectionInfo] {
        var indexPaths: [Entity: EntitySectionInfo] = [:]
        
        visibleSections.enumerated().forEach { (index: Int, section: EntityTableSection<Entity>) in
            section.fetchedObjects.enumerated()
                .filter { $1.hasChanges }
                .forEach { indexPaths[$0.element] = (section, IndexPath(row: $0.offset, section: index)) }
        }
        
        return indexPaths
    }
    
    private func section(for entity: Entity) -> EntityTableSection<Entity>? {
        return entity.isDeleted ? nil : sections.first { $0.isIncluded(entity) }
    }
    
}
