//
//  TRMosaicColumn.swift
//  Pods
//
//  Created by Vincent Le on 7/7/16.
//
//
import UIKit

struct TRMosaicRows {
    
    var rows:[TRMosaicRow]
    
    var smallestRow:TRMosaicRow {
        return rows.sorted().first!
    }
    
    init() {
        rows = [TRMosaicRow](repeating: TRMosaicRow(), count: 2)
    }
    
    subscript(index: Int) -> TRMosaicRow {
        get {
            return rows[index]
        }
        set(newRow) {
            rows[index] = newRow
        }
    }
}

struct TRMosaicRow {
    
    var rowWidth:CGFloat
    
    init() {
        rowWidth = 0
    }
    
    mutating func appendToRow(withWidth width:CGFloat) {
        rowWidth += width
    }
}

extension TRMosaicRow: Equatable { }
extension TRMosaicRow: Comparable { }

// MARK: Equatable

func ==(lhs: TRMosaicRow, rhs: TRMosaicRow) -> Bool {
    return lhs.rowWidth == rhs.rowWidth
}

// MARK: Comparable

func <=(lhs: TRMosaicRow, rhs: TRMosaicRow) -> Bool {
    return lhs.rowWidth <= rhs.rowWidth
    
}

func >(lhs: TRMosaicRow, rhs: TRMosaicRow) -> Bool {
    return lhs.rowWidth > rhs.rowWidth
}

func <(lhs: TRMosaicRow, rhs: TRMosaicRow) -> Bool {
    return lhs.rowWidth < rhs.rowWidth
}

func >=(lhs: TRMosaicRow, rhs: TRMosaicRow) -> Bool {
    return lhs.rowWidth >= rhs.rowWidth
}
