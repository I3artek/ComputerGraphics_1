//
//  Filters.swift
//  ComputerGraphics_1
//
//  Created by I3artek on 02/03/2025.
//

import Foundation
import Metal

struct FilterWrapper: Identifiable {
    var id = UUID()
    
    var filter: Filter
    var description: String
    
    init(filter: Filter, description: String) {
        self.filter = filter
        self.description = description
    }
}

protocol Filter {
}

struct LinearFilter: Filter {
    public var name: String
    
    init(name: String) {
        self.name = name
    }
}

struct ConvolutionFilter: Filter {
}
