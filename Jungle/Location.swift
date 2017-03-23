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
    
    fileprivate var key:String                    // Key in database
    fileprivate var name:String
    fileprivate var address:String
    fileprivate var coordinates:CLLocation
    
    init(key:String, name:String, address:String, coordinates:CLLocation)
    {
        self.key          = key
        self.name        = name
        self.address     = address
        self.coordinates = coordinates

    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObject(forKey: "key") as! String
        let name = decoder.decodeObject(forKey: "name") as! String
        let address = decoder.decodeObject(forKey: "address") as! String
        let coordinates = decoder.decodeObject(forKey: "coordinates") as! CLLocation
        self.init(key: key, name: name, address: address, coordinates: coordinates)
        
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(name, forKey: "name")
        coder.encode(address, forKey: "address")
        coder.encode(coordinates, forKey: "coordinates")
    }
    
    /* Getters */
    
    func getKey() -> String
    {
        return key
    }
    
    func getName()-> String
    {
        return name
    }
    
    func getAddress() -> String
    {
        return address
    }
    
    func getShortAddress() -> String {
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
    
    func getCoordinates() -> CLLocation
    {
        return coordinates
    }
    
    /*func getStory() -> Story {
        return story
    }
    
    func getContributers() -> [String:Any] {
        return contributers
    }*/
    
    func getDistance() -> Double {
        let lastLocation = GPSService.sharedInstance.lastLocation!
        return lastLocation.distance(from: coordinates)
    }
}

