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
import SwiftMessages

class MapViewController: UIViewController {
    
    var messageWrapper:SwiftMessages!
    
    let subscriberName = "MapViewController"
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var locationBGView: GradientContainerView!
    @IBOutlet weak var mapContainer: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationAddressLabel: UILabel!
    var blurView:UIVisualEffectView!
    
    var mapView:GMSMapView?
    var locationHeaderRef:LocationHeaderView!

    let cellIdentifier = "locationCell"
    
    @IBOutlet weak var nearbyLocationsLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        messageWrapper = SwiftMessages()
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = view.bounds
        view.insertSubview(blurView, at: 0)
        view.backgroundColor = UIColor.clear
        
        if let labelSuperview = locationLabel.superview {
            
            labelSuperview.layer.cornerRadius = labelSuperview.frame.height / 2
            labelSuperview.clipsToBounds = true
            

            labelSuperview.applyShadow(radius: 1.0, opacity: 0.75, height: 0.0, shouldRasterize: false)
            labelSuperview.layer.masksToBounds = true
            //labelSuperview.layer.borderColor = UIColor.white.cgColor
           // labelSuperview.layer.borderWidth = 2.0
        }
    }
    
    var didHideLocationAlert = false
}

extension MapViewController: GPSServiceProtocol {
    func authorizationDidChange() {
        
    }

    func tracingLocation(_ currentLocation: CLLocation) {
        messageWrapper.hideAll()
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
        messageWrapper.hideAll()
        LocationService.sharedInstance.requestNearbyLocations()
    }
    
    func nearbyPlacesUpdate(_ likelihoods: [GMSPlaceLikelihood]) {
        print("nearbyPlacesUpdate")
        if let first = likelihoods.first {
            
            self.locationLabel.text = first.place.name
            print("nearest location: \(first.place.name)")
            if let address = first.place.formattedAddress {
                self.locationAddressLabel.text = getShortFormattedAddress(address)
            }
            locationHeaderRef.isSearching(false)
            locationHeaderRef.locationLabel.text = first.place.name
            
        } else {
            print("Nothing nearby")
            
            self.locationLabel.text = "Nothing nearby"
            self.locationAddressLabel.text = ""
            locationHeaderRef.isSearching(false)
            locationHeaderRef.locationLabel.text = "Nothing nearby"
        }
    }
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        
        if !didHideLocationAlert {
            let tap = UITapGestureRecognizer(target: self, action: #selector(alertTapped))
            Alerts.showNoLocationServicesAlert(inWrapper: messageWrapper, tap: tap)
        }
        
    }
    
    func alertTapped() {
        didHideLocationAlert = true
        messageWrapper.hideAll()
    }
    
    func horizontalAccuracyUpdated(_ accuracy: Double?) {
        if let a = accuracy {
          self.accuracyLabel.text = "Accuracy: \(roundToOneDecimal(a))m"
        } else {
        self.accuracyLabel.text = "Accuracy Unavailable"
        }
    }
}
