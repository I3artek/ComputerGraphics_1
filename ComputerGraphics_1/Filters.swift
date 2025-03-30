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

struct UniformQuantizationFilter: Filter {
    public var colorCount: UInt32
    
    init(colorCount: UInt32) {
        if(colorCount == 0) {
            self.colorCount = 1
        } else {
            self.colorCount = colorCount
        }
    }
}

struct PixelizeFilter: Filter {
    public var size: UInt32
    
    init(size: UInt32) {
        self.size = size
    }
}

struct LinearFilter: Filter {
    public var name: String
    
    init(name: String) {
        self.name = name
    }
}

struct ConvolutionFilter: Filter {
    public var matrix = ConvMatrix()
    public var arrayMatrix: [[Int8]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    public var matrixString: String = ""
    
    mutating func updateMatrix(str: String) {
        let rows = str.split(separator: ";")
        for i in 0...8 {
            let row = rows[i]
            let vals = row.split(separator: ",")
            for j in 0...8 {
                let val = vals[j]
                self.arrayMatrix[i][j] = Int8(Int(val) ?? Int(self.arrayMatrix[i][j]))
            }
        }
        matrix.values = MatrixTo9Tuple9Tuple(matrix: arrayMatrix)
    }
    
    func getString() -> String {
        var str = ""
        for row in arrayMatrix {
            for value in row {
                str += "\(value),"
            }
            str += ";"
        }
        return str
    }
    
    mutating func setString() {
        matrixString = getString()
    }
}

// This is ugly, but it's the only way
func ArrayTo9Tuple(array: [Int8]) -> (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) {
    return (array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8])
}

func MatrixTo9Tuple9Tuple(matrix: [[Int8]]) -> ((Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8),
                                                (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)) {
    return (ArrayTo9Tuple(array: matrix[0]),
            ArrayTo9Tuple(array: matrix[1]),
            ArrayTo9Tuple(array: matrix[2]),
            ArrayTo9Tuple(array: matrix[3]),
            ArrayTo9Tuple(array: matrix[4]),
            ArrayTo9Tuple(array: matrix[5]),
            ArrayTo9Tuple(array: matrix[6]),
            ArrayTo9Tuple(array: matrix[7]),
            ArrayTo9Tuple(array: matrix[8]))
}
