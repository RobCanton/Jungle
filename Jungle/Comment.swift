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

class AnonymousComment: Comment {
    
    private(set) var adjective:String
    private(set) var animal:String
    private(set) var colorHexcode:String
    var anonName:String {
        get {
            return "\(adjective)\(animal)"
        }
    }
    
    var color:UIColor {
        get {
            return hexStringToUIColor(hex: colorHexcode)
        }
    }
    
    init(key:String, author:String, text:String, timestamp:Double, adjective:String, animal:String, colorHexcode:String)
    {
        self.adjective = adjective
        self.animal = animal
        self.colorHexcode = colorHexcode
        super.init(key: key, author: author, text: text, timestamp: timestamp)
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
