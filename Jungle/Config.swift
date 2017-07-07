//
//  Config.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-04.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase


class Range: NSObject {
    
    private(set) var key:String                    // Key in database
    private(set) var distance:Int
    private(set) var label:String
    
    init(key:String, distance:Int, label:String)
    {
        self.key      = key
        self.distance = distance
        self.label    = label
    }
    
}

class Config {
    
    static let ref = Database.database().reference()
    
    static var ranges:[Range] = [
        Range(key: "1", distance: 1, label: "1 km"),
        Range(key: "5", distance: 5, label: "5 km"),
        Range(key: "10", distance: 10, label: "10 km"),
        Range(key: "25", distance: 25, label: "25 km"),
        Range(key: "50", distance: 50, label: "50 km"),
        Range(key: "100", distance: 100, label: "100 km"),
        Range(key: "200", distance: 200, label: "200 km")
    ]
    
    static func getRanges() {
        let rangeRef = ref.child("config/client/ranges")
        rangeRef.observeSingleEvent(of: .value, with: { snapshot in
            
            var _ranges = [Range]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                if let dict = childSnap.value as? [String:Any] {
                    let distance = dict["d"] as! Int
                    let label = dict["l"] as! String
                    let range = Range(key: childSnap.key, distance: distance, label: label)
                    _ranges.append(range)
                }
            }
            ranges = _ranges
        })
    }
    
}
