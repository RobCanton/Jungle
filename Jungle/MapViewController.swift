//
//  MapViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-24.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapContainer: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationAddressLabel: UILabel!
    var blurView:UIVisualEffectView!
    
    var mapView:GMSMapView?

    
    let cellIdentifier = "locationCell"
    
    @IBOutlet weak var nearbyLocationsLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = view.bounds
        view.insertSubview(blurView, at: 0)
        
        view.backgroundColor = UIColor.clear
        GPSService.sharedInstance.delegate = self
        GPSService.sharedInstance.startUpdatingLocation()
        
        if let labelSuperview = locationLabel.superview {
            labelSuperview.layer.cornerRadius = labelSuperview.frame.height / 4
            labelSuperview.clipsToBounds = true
            labelSuperview.layer.borderColor = UIColor.white.cgColor
            labelSuperview.layer.borderWidth = 2.0
        }
        
    }
}

extension MapViewController: GPSServiceDelegate {
    func tracingLocation(_ currentLocation: CLLocation) {
        //LocationService.sharedInstance.requestNearbyLocations(currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        // singleton for get last location
        if mapView == nil {
            
            let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 18.0)
            mapView = GMSMapView.map(withFrame: mapContainer.bounds, camera: camera)
            mapContainer.addSubview(mapView!)
            mapView!.backgroundColor = UIColor.black
            mapView!.isMyLocationEnabled = true
            mapView!.settings.scrollGestures = false
            mapView!.settings.rotateGestures = true
            mapView!.settings.tiltGestures = false
            mapView!.isBuildingsEnabled = true
            mapView!.isIndoorEnabled = true
            mapView!.alpha = 0.65
            mapContainer.layer.cornerRadius = 12.0
            mapContainer.clipsToBounds = true
            
            do {
                // Set the map style by passing the URL of the local file.
                if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
                    mapView!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } else {
                    NSLog("Unable to find style.json")
                }
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
            
        } else{
            mapView!.animate(toLocation: currentLocation.coordinate)
        }
    }
    
    func significantLocationUpdate(_ location: CLLocation) {
        LocationService.sharedInstance.requestNearbyLocations(location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func nearbyPlacesUpdate(_ likelihoods: [GMSPlaceLikelihood]) {
        if let first = likelihoods.first {
            self.locationLabel.text = first.place.name
            if let address = first.place.formattedAddress {
                self.locationAddressLabel.text = getShortFormattedAddress(address)
            }
            if let locationHeader = globalMainRef?.locationHeader {
                locationHeader.locationLabel.text = first.place.name
                if locationHeader.isHidden {
                    locationHeader.alpha = 0.0
                    locationHeader.isHidden = false
                    UIView.animate(withDuration: 0.35, animations: {
                        locationHeader.alpha = 1.0
                    })
                }
            }
            
        } else {
            self.locationLabel.text = "Nothing nearby"
            self.locationAddressLabel.text = ""
            if let locationHeader = globalMainRef?.locationHeader {
                locationHeader.locationLabel.text = ""
                if !locationHeader.isHidden {
                    locationHeader.isHidden = false
                    UIView.animate(withDuration: 0.35, animations: {
                        locationHeader.alpha = 0.0
                    })
                }
            }
        }
    }
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        print(error.code)
        
    }
}
