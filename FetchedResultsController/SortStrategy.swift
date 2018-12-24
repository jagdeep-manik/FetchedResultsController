//
//  SortStrategy.swift
//  FetchedResultsController
//
//  Created by Jagdeep Manik on 12/17/18.
//  Copyright © 2018 Jagdeep Manik. All rights reserved.
//

import Foundation

enum SortStrategy {
    case name
    case time
    
    var opposite: SortStrategy {
        switch self {
        case .name:
            return .time
        case .time:
            return .name
        }
    }
    
    var title: String {
        switch self {
        case .name:
            return "Name"
        case .time:
            return "Time"
        }
    }
}

protocol SortStrategyDelegate {
    
    func sortStrategyChanged(to strategy: SortStrategy)
    
}
