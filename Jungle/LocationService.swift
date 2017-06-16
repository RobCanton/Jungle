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
    fileprivate let ref = Database.database().reference()
    
    var nearbyLocations = [Location]()
    var radius = 25
    
    var delegate:LocationDelegate?
    var gps_service:GPSService?
    
    static let sharedInstance : LocationService = {
        let instance = LocationService()
        return instance
    }()

    override init() {
        super.init()
    }
    
    func requestNearbyLocations() {
        
        guard let lastLocation = gps_service?.getLastLocation() else { return }
        let uid = mainStore.state.userState.uid
        let apiRef = ref.child("users/location/coordinates/\(uid)")
        apiRef.setValue([
            "lat": lastLocation.coordinate.latitude,
            "lon": lastLocation.coordinate.longitude,
            "rad": radius,
            "ts": [".sv": "timestamp"]
            ])
    }
    
    func getLocationInfo(_ locationKey:String, completion: @escaping (_ location:Location?)->()) {
        
        if let cachedLocation = dataCache.object(forKey: "place-\(locationKey)" as NSString) as? Location {
            completion(cachedLocation)
        } else {
            let locRef = ref.child("places/info/\(locationKey)")
            
            locRef.observeSingleEvent(of: .value, with: { snapshot in
                var location:Location?
                
                if snapshot.exists() {
                    let dict         = snapshot.value as! [String:AnyObject]
                    let name         = dict["name"] as! String
                    let lat          = dict["lat"] as! Double
                    let lon          = dict["lon"] as! Double
                    let address      = dict["address"] as! String
                    let coord = CLLocation(latitude: lat, longitude: lon)
                    
                    var types = [String]()
                    if let _types = dict["types"] as? [String:Bool] {
                        for (_type, _) in _types {
                            types.append(_type)
                        }
                    }
                    
                    location = Location(key: snapshot.key, name: name, address: address, coordinates: coord, types: types)
                    dataCache.setObject(location!, forKey: "place-\(locationKey)" as NSString)
                }
                
                completion(location)
            })
        }
    }
    
    func getLocationInfo(withReturnKey locationKey:String, completion: @escaping (_ key:String, _ location:Location?)->()) {
        getLocationInfo(locationKey) { location in
            completion(locationKey, location)
        }
    }
    
    func getLocationInfo(withCheck check:Int, locationKey:String, completion: @escaping (_ check:Int, _ location:Location?)->()) {
        getLocationInfo(locationKey) { location in
            completion(check, location)
        }
    }
    func getLocationStory(_ key:String, withDistance distance:Double, completion: @escaping ((_ story:LocationStory?)->())) {
        
        let storyRef = Database.database().reference().child("places/story/\(key)")
        
        storyRef.queryOrderedByValue().observeSingleEvent(of: .value, with: { snapshot in
            var story:LocationStory?
            var postKeys = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                postKeys.append((childSnap.key, childSnap.value as! Double))
            }

            if postKeys.count > 0 {
                story = LocationStory(postKeys: postKeys, locationKey: key, distance: distance)
            }
            
            completion(story)
            
        }, withCancel: { error in
            completion(nil)
        })
    }
    

}

extension Dictionary where Value: Comparable {
    var valueKeySorted: [(Key, Value)] {
        return sorted{ if $0.value != $1.value { return $0.value > $1.value } else { return String(describing: $0.key) < String(describing: $1.key) } }
    }
}

