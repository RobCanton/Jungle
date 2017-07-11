//
//  AnonObject.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-11.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class AnonObject:NSObject
{
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
    
    init(adjective:String, animal:String, colorHexcode:String) {
        self.adjective = adjective
        self.animal = animal
        self.colorHexcode = colorHexcode
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let adjective = decoder.decodeObject(forKey: "adjective") as! String
        let animal = decoder.decodeObject(forKey: "animal") as! String
        let colorHexcode = decoder.decodeObject(forKey: "colorHexcode") as! String

        self.init(adjective:adjective, animal:animal, colorHexcode:colorHexcode)
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(adjective, forKey: "adjective")
        coder.encode(animal, forKey: "animal")
        coder.encode(colorHexcode, forKey: "colorHexcode")
    }
}
