//
//  LocationService.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//
import Foundation
import CoreLocation
import Firebase


protocol LocationDelegate {
    func locationsUpdated(locations:[Location])
}

class LocationService: NSObject {
    
    fileprivate let locationsCache = NSCache<NSString, AnyObject>()
    
    fileprivate let ref = FIRDatabase.database().reference()

    
    var nearbyLocations = [Location]()
    var radius = 10000
    
    var delegate:LocationDelegate?
    
    static let sharedInstance : LocationService = {
        let instance = LocationService()
        return instance
    }()

    
    override init() {
        super.init()
        
    }
    
    func requestNearbyLocations(_ latitude:Double, longitude:Double) {
        
        let uid = mainStore.state.userState.uid
        let apiRef = ref.child("users/location/coordinates/\(uid)")
        apiRef.setValue([
            "lat": latitude,
            "lon": longitude,
            "rad": radius
            ])
    }
    
    func listenToResponses() {
        let uid = mainStore.state.userState.uid
        let responseRef = ref.child("api/responses/locations/\(uid)")
        responseRef.observe(.value, with: { snapshot in
            responseRef.removeValue()
            
            if snapshot.exists() {
                let placeIds = snapshot.value! as! [String:Double]
                self.getLocations(placeIds, completion:  { locations in
                    self.nearbyLocations = locations
                    self.delegate?.locationsUpdated(locations: self.nearbyLocations)
                })
            }
        })
    }
    
    
    func getLocations(_ locationDict:[String:Double], completion: @escaping (_ locations: [Location]) -> ()) {
        var locations = [Location]()
        var count = 0
        
        for (key, dist) in locationDict {
            getLocation(key, completion: { location in
                if location != nil {
                    locations.append(location!)
                }
                
                count += 1
                
                if count >= locationDict.count {
                    DispatchQueue.main.async {
                        completion(locations)
                    }
                }
            })
        }
    }
    
    func getLocation(_ locationKey:String, completion: @escaping (_ location:Location?)->()) {
        
        let locRef = ref.child("places/\(locationKey)")
        
        locRef.observeSingleEvent(of: .value, with: { snapshot in
            var location:Location?
            
            if snapshot.exists() {
                let dict         = snapshot.value as! [String:AnyObject]
                let info         = dict["info"] as! [String:AnyObject]
                let name         = info["name"] as! String
                let lat          = info["lat"] as! Double
                let lon          = info["lon"] as! Double
                let address      = info["address"] as! String
                let coord = CLLocation(latitude: lat, longitude: lon)
                
                /*var postKeys = [(String,Double)]()
                if let _postsKeys = dict["posts"] as? [String:Double] {
                    postKeys = _postsKeys.valueKeySorted
                }
                
                var contributers = [String:Any]()
                if snapshot.hasChild("contributers") {
                    contributers = dict["contributers"] as! [String:Any]
                }*/
                
                location = Location(key: snapshot.key, name: name, address: address, coordinates: coord)
            }
            
            completion(location)
        })
    }
    
    func getLocationInfo(_ locationKey:String, completion: @escaping (_ location:Location?)->()) {
        
        if let cachedLocation = dataCache.object(forKey: "place-\(locationKey)" as NSString) as? Location {
            completion(cachedLocation)
        } else {
            let locRef = ref.child("places/\(locationKey)/info")
            
            locRef.observeSingleEvent(of: .value, with: { snapshot in
                var location:Location?
                
                if snapshot.exists() {
                    let dict         = snapshot.value as! [String:AnyObject]
                    let name         = dict["name"] as! String
                    let lat          = dict["lat"] as! Double
                    let lon          = dict["lon"] as! Double
                    let address      = dict["address"] as! String
                    let coord = CLLocation(latitude: lat, longitude: lon)
                    
                    location = Location(key: snapshot.key, name: name, address: address, coordinates: coord)
                    dataCache.setObject(location!, forKey: "place-\(locationKey)" as NSString)
                }
                
                completion(location)
            })
        }
    }
    
    func getLocationStory(_ locationKey:String, completon: @escaping (_ story: LocationStory?)->()) {
        
        let locRef = ref.child("places/\(locationKey)/posts")
        
        locRef.observeSingleEvent(of: .value, with: { snapshot in
            var story:LocationStory?

            if let _postsKeys = snapshot.value as? [String:Double] {
                let postKeys:[(String,Double)] = _postsKeys.valueKeySorted
                story = LocationStory(postKeys: postKeys, locationKey: locationKey)
            }
            completon(story)
        })
    }
}

extension Dictionary where Value: Comparable {
    var valueKeySorted: [(Key, Value)] {
        return sorted{ if $0.value != $1.value { return $0.value > $1.value } else { return String(describing: $0.key) < String(describing: $1.key) } }
    }
}

