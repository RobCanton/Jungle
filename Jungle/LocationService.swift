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
    var radius = 100
    
    var delegate:LocationDelegate?
    var gps_service:GPSService?
    
    static let sharedInstance : LocationService = {
        let instance = LocationService()
        return instance
    }()

    override init() {
        super.init()
    }
    
    func fetchRadius() {
        let uid = mainStore.state.userState.uid
        let radiusRef = ref.child("users/settings/\(uid)/radius")
        radiusRef.observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? Int {
                self.radius = value
            }
        })
    }
    
    func setSearchRadius(_ newRadius: Int) {
        radius = newRadius
        let uid = mainStore.state.userState.uid
        let radiusRef = ref.child("users/settings/\(uid)/radius")
        radiusRef.setValue(radius) { error, ref in
            
        }
        requestNearbyLocations()
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
    
    func getCityInfoInfo(_ key:String, completion: @escaping (_ city:City?)->()) {
        
        if let cachedCity = dataCache.object(forKey: "city-\(key)" as NSString) as? City {
            completion(cachedCity)
        } else {
            let locRef = ref.child("cities/info/\(key)")
            
            locRef.observeSingleEvent(of: .value, with: { snapshot in
                var city:City?
                
                if snapshot.exists() {
                    let dict         = snapshot.value as! [String:AnyObject]
                    let name         = dict["city"] as! String
                    let country      = dict["country"] as! String
                    let lat          = dict["lat"] as! Double
                    let lon          = dict["lon"] as! Double
                    
                    let coord = CLLocation(latitude: lat, longitude: lon)
                    
                    
                    city = City(key: snapshot.key, name: name, country: country, coordinates: coord)
                    dataCache.setObject(city!, forKey: "city-\(key)" as NSString)
                }
                
                completion(city)
            })
        }
    }
    
    func getCityInfoInfo(withCheck check:Int, key:String, completion: @escaping (_ check:Int, _ city:City?)->()) {
        getCityInfoInfo(key) { city in
            completion(check, city)
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
            var contributers = [String:Bool]()
            var postKeys = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                if let dict = childSnap.value as? [String:Any] {
                    let timestamp = dict["t"] as! Double
                    let uid = dict["u"] as! String
                    contributers[uid] = true
                    postKeys.append((childSnap.key, timestamp))

                }
            }

            if postKeys.count > 0 { //&& contributers.count > 1 {
                story = LocationStory(postKeys: postKeys, locationKey: key, distance: distance)
            }
            
            completion(story)
            
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    func getCityStory(_ key:String, withDistance distance:Double, completion: @escaping ((_ story:CityStory?)->())) {
        
        let storyRef = Database.database().reference().child("cities/posts/\(key)")
        
        storyRef.queryOrderedByValue().observeSingleEvent(of: .value, with: { snapshot in
            var story:CityStory?
            var contributers = [String:Bool]()
            var postKeys = [(String,Double)]()
            for child in snapshot.children {
                
                let childSnap = child as! DataSnapshot
                if let dict = childSnap.value as? [String:Any] {
                    let timestamp = dict["t"] as! Double
                    let uid = dict["a"] as! String
                    contributers[uid] = true
                    print("AYYYEE!: \(childSnap.key)")
                    postKeys.append((childSnap.key, timestamp))
                    
                }
            }
            
            if postKeys.count > 0 { //&& contributers.count > 1 {
                story = CityStory(postKeys: postKeys, cityKey: key, distance: distance)
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

