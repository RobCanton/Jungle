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
    
    let subscriberName = "MapViewController"
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var locationBGView: UIView!
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
        
        if let labelSuperview = locationLabel.superview {
            
            labelSuperview.layer.cornerRadius = labelSuperview.frame.height / 4
            labelSuperview.clipsToBounds = true
            
            let gradient = CAGradientLayer()
            gradient.frame = locationBGView.bounds
            gradient.colors = [
                lightAccentColor.cgColor,
                darkAccentColor.cgColor
            ]
            gradient.locations = [0.0, 1.0]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 0)
            locationBGView.layer.insertSublayer(gradient, at: 0)
            locationBGView.layer.masksToBounds = true
            labelSuperview.applyShadow(radius: 1.0, opacity: 0.75, height: 0.0, shouldRasterize: false)
            labelSuperview.layer.masksToBounds = true
            //labelSuperview.layer.borderColor = UIColor.white.cgColor
           // labelSuperview.layer.borderWidth = 2.0
        }
    }
}

extension MapViewController: GPSServiceProtocol {
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
        print("nearbyPlacesUpdate")
        if let first = likelihoods.first {
            
            self.locationLabel.text = first.place.name
            print("nearest location: \(first.place.name)")
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
            print("Nothing nearby")
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
    
    func horizontalAccuracyUpdated(_ accuracy: Double?) {
        if let a = accuracy {
          self.accuracyLabel.text = "Accuracy: \(roundToOneDecimal(a))m"
        } else {
        self.accuracyLabel.text = "Accuracy Unavailable"
        }
    }
}