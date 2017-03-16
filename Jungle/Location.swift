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
    
    fileprivate var id:String                    // Key in database
    fileprivate var name:String
    fileprivate var address:String
    fileprivate var coordinates:CLLocation
    fileprivate var story:Story
    fileprivate var contributers:[String:Any]
    
    init(key:String, name:String, address:String, coordinates:CLLocation, postKeys: [(String,Double)], contributers: [String:Any])
    {
        self.id          = key
        self.name        = name
        self.address     = address
        self.coordinates = coordinates
        self.story       = Story(postKeys: postKeys)
        self.contributers = contributers
    }
    
    /* Getters */
    
    func getId() -> String
    {
        return id
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
    
    func getStory() -> Story {
        return story
    }
    
    func getContributers() -> [String:Any] {
        return contributers
    }
    
    func getDistance() -> Double {
        let lastLocation = GPSService.sharedInstance.lastLocation!
        return lastLocation.distance(from: coordinates)
    }
}

