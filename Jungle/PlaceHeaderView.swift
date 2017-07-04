//
//  PlaceHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-07.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class PlaceHeaderView: UICollectionReusableView {

    var mapView:GMSMapView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setLocation(_ location:Location) {
        if mapView == nil {
            
            let camera = GMSCameraPosition.camera(withTarget: location.coordinates.coordinate, zoom: 16.0)
            mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0, width: self.bounds.width, height : self.bounds.height - 1.5), camera: camera)
            self.addSubview(mapView!)
            mapView!.backgroundColor = UIColor.black
            mapView!.isMyLocationEnabled = true
            mapView!.settings.scrollGestures = false
            mapView!.settings.rotateGestures = true
            mapView!.settings.tiltGestures = false
            mapView!.isBuildingsEnabled = true
            mapView!.isIndoorEnabled = true
           
            let marker = GMSMarker(position: location.coordinates.coordinate)
            marker.map = mapView
            
//            
//            do {
//                // Set the map style by passing the URL of the local file.
//                if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
//                    mapView!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
//                } else {
//                    NSLog("Unable to find style.json")
//                }
//            } catch {
//                NSLog("One or more of the map styles failed to load. \(error)")
//            }
            
        } else{
            mapView!.animate(toLocation: location.coordinates.coordinate)
        }
        
    }
    
}
