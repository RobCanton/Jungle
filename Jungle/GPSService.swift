import Foundation
import CoreLocation
import ReSwift
import GoogleMaps
import GooglePlaces

protocol GPSServiceDelegate {
    func tracingLocation(_ currentLocation: CLLocation)
    func significantLocationUpdate( _ location: CLLocation)
    func tracingLocationDidFailWithError(_ error: NSError)
    
    func nearbyPlacesUpdate(_ likelihoods:[GMSPlaceLikelihood])
}

class GPSService: NSObject, CLLocationManagerDelegate {
    
    static let sharedInstance : GPSService = {
        let instance = GPSService()
        return instance
    }()
    
    var locationManager: CLLocationManager?
    var lastLocation: CLLocation?
    
    var lastSignificantLocation: CLLocation?
    
    var delegate: GPSServiceDelegate?
    
    var placesClient: GMSPlacesClient!
    
    var likelihoods = [GMSPlaceLikelihood]()
    
    override init() {
        super.init()
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
        }
        
        // singleton for get last location
        self.lastLocation = location
        //print("ACCURACY: \(location.horizontalAccuracy)")
        
        if lastSignificantLocation == nil {
            lastSignificantLocation = location
            updateLocationSignificant(lastSignificantLocation!)
        } else {
            let dist = lastSignificantLocation!.distance(from: location)
            if dist > 25.0 {
                lastSignificantLocation = location
                updateLocationSignificant(lastSignificantLocation!)
            }
        }
        
        // use for real time update location
        updateLocation(location)
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // do on error
        updateLocationDidFailWithError(error as NSError)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //delegate?.authorizationChange()
    }
    
    
    // Private function
    fileprivate func updateLocation(_ currentLocation: CLLocation){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tracingLocation(currentLocation)
    }
    
    // Private function
    fileprivate func updateLocationSignificant(_ location: CLLocation){
        guard let delegate = self.delegate else {
            return
        }
        getCurrentPlaces()
        delegate.significantLocationUpdate(location)
        
    }
    
    fileprivate func updateLocationDidFailWithError(_ error: NSError) {
        
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tracingLocationDidFailWithError(error)
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
                self.delegate?.nearbyPlacesUpdate(self.likelihoods)
                
            }
        })
    }
}

