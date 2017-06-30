//
//  Comment.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-29.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class Comment: NSObject {
    
    private(set) var key:String                    // Key in database
    private(set) var author:String
    private(set) var text:String
    private(set) var date:Date
    
    init(key:String, author:String, text:String, timestamp:Double)
    {
        self.key     = key
        self.author  = author
        self.text    = text
        self.date    = Date(timeIntervalSince1970: timestamp/1000)
    }
    
    
}

func < (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

func > (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedDescending
}

func == (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedSame
}
