//
//  Upload.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-06.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import GoogleMaps
import GooglePlaces

class Upload {
    var toProfile:Bool = false
    var toStory:Bool = false
    var toNearby:Bool = false
    var caption:String?
    var coordinates:CLLocation?
    var place:GMSPlace?
    var image:UIImage?
    var videoURL:URL?
    var recipients:[String:Bool] = [:]
    
    func printDescription() {
        
        print("\ntoStory: \(toStory)")
        print("toProfile: \(toProfile)")
        print("place: \(place)")
        print("recipients: \(recipients)")
    }
}
