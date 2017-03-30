import Foundation
import CoreLocation
import ReSwift
import GoogleMaps
import GooglePlaces

protocol ServiceProtocol {}

class Service: NSObject {
    
    fileprivate var subscribers: [String:ServiceProtocol]
    
    init(_ subscribers:[String:ServiceProtocol]) {
        self.subscribers = subscribers
    }
    
    func subscribe(_ name:String, subscriber:ServiceProtocol) {
        subscribers[name] = subscriber
    }
    
    func unsubscribe(_ name:String) {
        self.subscribers[name] = nil
    }

}


protocol GPSServiceProtocol:ServiceProtocol {
    func tracingLocation(_ currentLocation: CLLocation)
    func significantLocationUpdate( _ location: CLLocation)
    func tracingLocationDidFailWithError(_ error: NSError)
    func nearbyPlacesUpdate(_ likelihoods:[GMSPlaceLikelihood])
    func horizontalAccuracyUpdated(_ accuracy:Double?)
}


class GPSService: Service, CLLocationManagerDelegate {
    
    fileprivate var locationManager: CLLocationManager?
    fileprivate var lastLocation: CLLocation?
    fileprivate var currentAccuracy:Double?
    fileprivate var lastSignificantLocation: CLLocation?
    fileprivate var placesClient: GMSPlacesClient!
    fileprivate var likelihoods = [GMSPlaceLikelihood]()
    
    override init(_ subscribers:[String:ServiceProtocol]) {
        super.init(subscribers)
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else {
            return
        }
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                print("No access")
                locationManager.requestWhenInUseAuthorization()
                break
            case .restricted, .denied:
                break
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
                break
            }
        } else {
            print("Location services are not enabled")
            locationManager.requestWhenInUseAuthorization()
        }
        if CLLocationManager.authorizationStatus() == .notDetermined {
            // requestWhenInUseAuthorization
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // The accuracy of the location data
        locationManager.distanceFilter = 0 // The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
        locationManager.delegate = self
    }
    
    internal override func subscribe(_ name: String, subscriber: ServiceProtocol) {
        if subscriber is GPSServiceProtocol {
            super.subscribe(name, subscriber: subscriber)
        }
    }
    
    fileprivate func getSubscribers() -> [String:GPSServiceProtocol]? {
        guard let subscribers = subscribers as? [String:GPSServiceProtocol] else { return nil }
        return subscribers
    }
    
    func getLastLocation() -> CLLocation? { return lastLocation }
    func getLikelihoods() -> [GMSPlaceLikelihood] { return likelihoods }
    
    func isAuthorized() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                self.locationManager?.requestWhenInUseAuthorization()
                return true
            case .restricted, .denied:
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            }
        } else {
            return false
        }
    }
    
    func startUpdatingLocation() {
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        
        guard let subscribers = getSubscribers() else { return }
        currentAccuracy = location.horizontalAccuracy
        subscribers.forEach { $0.value.horizontalAccuracyUpdated(currentAccuracy) }
        if location.horizontalAccuracy > 100.0 { return }
        self.lastLocation = location
        
        if lastSignificantLocation == nil {
            lastSignificantLocation = location
            subscribers.forEach { $0.value.significantLocationUpdate(location) }
            getCurrentPlaces()
        } else {
            let dist = lastSignificantLocation!.distance(from: location)
            if dist > 25.0 {
                lastSignificantLocation = location
                subscribers.forEach { $0.value.significantLocationUpdate(location) }
                getCurrentPlaces()
            }
        }
        
        subscribers.forEach { $0.value.tracingLocation(location) }
        
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // do on error
        updateLocationDidFailWithError(error as NSError)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //delegate?.authorizationChange()
    }
    
    internal func updateLocationDidFailWithError(_ error: NSError) {
        guard let subscribers = getSubscribers() else { return }
        subscribers.forEach { $0.value.tracingLocationDidFailWithError(error)}
    }
    
    func getCurrentPlaces() {
        
        placesClient = GMSPlacesClient.shared()
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                var temp = [GMSPlaceLikelihood]()
                for likelihood in placeLikelihoodList.likelihoods {
                    if likelihood.likelihood >= 0.1 {
                        temp.append(likelihood)
                    }
                }
                self.likelihoods = temp
                guard let subscribers = self.getSubscribers() else { return }
                subscribers.forEach { $0.value.nearbyPlacesUpdate(self.likelihoods)}
                
            }
        })
    }
    
    
}


