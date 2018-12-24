//
//  ViewController.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/17/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    // MARK: - Static Vars
    
    static let dummyReservationCount = 100
    
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var standardTableView: UITableView!
    
    @IBOutlet weak var customTableView: UITableView!
    
    @IBOutlet weak var sortByButton: UIButton!
    
    
    // MARK: - IBActions
    
    /// Shuffle all reservations by changing their names and sections
    @IBAction func shuffleTapped(_ sender: Any) {
        let context = AppDelegate.shared.persistentContainer.viewContext
        
        context.perform {
            Reservation.findAll(in: context).forEach {
                $0.displayName = Fakie.randomName()
                $0.setSection(section: Fakie.randomSection())
            }
            
            try? context.save()
        }
    }
    
    /// Changes the sorting strategy
    @IBAction func sortByTapped(_ sender: Any) {
        sortByButton.setTitle("Sort By \(sortStrategy.title)", for: .normal)
        sortStrategy = sortStrategy.opposite
        standardDataSource?.sortStrategyChanged(to: sortStrategy)
    }
    
    @IBAction func purgeSectionTapped(_ sender: Any) {
        let context = AppDelegate.shared.persistentContainer.viewContext
        
        context.perform {
            for _ in 0..<10 {
                Reservation.generateRandom(in: context)
            }
            
            try? context.save()
        }
    }
    
    
    // MARK: - Vars/Lazy Vars
    
    private var standardDataSource: StandardTableViewDataSource?
    
    private var customDataSource: CustomTableViewDataSource?
    
    private var sortStrategy: SortStrategy = .name
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDummyData()
        setupStandardTableView()
        setupCustomTableView()
    }
    
    
    // MARK: - Private Functions
    
    private func loadDummyData() {
        let context = AppDelegate.shared.persistentContainer.viewContext
        
        context.performAndWait {
            // Clear all
            Reservation.deleteAll(in: context)
            
            // Create a ton
            (1...ViewController.dummyReservationCount).forEach { _ in
                Reservation.generateRandom(in: context)
            }
            
            // Save and refresh
            try? context.save()
            context.refreshAllObjects()
        }
    }
    
    private func setupStandardTableView() {
        let context = AppDelegate.shared.persistentContainer.viewContext
        standardDataSource = StandardTableViewDataSource(table: standardTableView, context: context)
        standardTableView.dataSource = standardDataSource
    }
    
    private func setupCustomTableView() {
        let context = AppDelegate.shared.persistentContainer.viewContext
        customDataSource = CustomTableViewDataSource(table: customTableView, context: context)
        customTableView.dataSource = customDataSource
    }


}

