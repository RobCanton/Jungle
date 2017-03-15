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
    
    init(key:String, name:String, address:String, coordinates:CLLocation, postKeys: [(String,Double)])
    {
        self.id          = key
        self.name        = name
        self.address     = address
        self.coordinates = coordinates
        self.story       = Story(postKeys: postKeys)
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
    
    func getCoordinates() -> CLLocation
    {
        return coordinates
    }
    
    func getStory() -> Story {
        return story
    }
}
