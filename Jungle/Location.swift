//
//  Location.swift
//  Riot
//
//  Created by Robert Canton on 2017-03-14.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import CoreLocation

class Location: NSObject {
    
    private(set) var key:String                    // Key in database
    private(set) var name:String
    private(set) var address:String
    private(set) var shortAddress:String
    private(set) var coordinates:CLLocation
    private(set) var types:[String]
    
    init(key:String, name:String, address:String, coordinates:CLLocation, types:[String])
    {
        self.key          = key
        self.name        = name
        self.address     = address
        self.coordinates = coordinates
        self.types       = types
        self.shortAddress = getShortFormattedAddress(address)

    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObject(forKey: "key") as! String
        let name = decoder.decodeObject(forKey: "name") as! String
        let address = decoder.decodeObject(forKey: "address") as! String
        let coordinates = decoder.decodeObject(forKey: "coordinates") as! CLLocation
        let types = decoder.decodeObject(forKey: "types") as! [String]
        self.init(key: key, name: name, address: address, coordinates: coordinates, types: types)
        
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(name, forKey: "name")
        coder.encode(address, forKey: "address")
        coder.encode(coordinates, forKey: "coordinates")
        coder.encode(types, forKey: "types")
    }
    
    /* Getters */
    
    func getDistance() -> Double {
       // let lastLocation = GPSService.sharedInstance.lastLocation!
        //return lastLocation.distance(from: coordinates)
        return 0 
    }
}

func getShortFormattedAddress(_ address: String) -> String {
    if let index = address.lowercased().characters.index(of: ",") {
        
        let firstHalf = address.substring(to: index)
        let secondHalf = address.substring(from: address.index(after: index))
        if let i = secondHalf.lowercased().characters.index(of: ",") {
            let secondCut = secondHalf.substring(to: i)
            return "\(firstHalf),\(secondCut)"
        }
        return firstHalf
    }
    return address
}

