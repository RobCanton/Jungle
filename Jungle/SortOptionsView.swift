//
//  SortOptionsView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-04-18.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import TGPControls

let distances = [1, 5, 10, 25, 50, 100, 200]


class SortOptionsView: UIView {
    
    
    @IBOutlet weak var slider: TGPDiscreteSlider!
    @IBOutlet weak var sliderLabels: TGPCamelLabels!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        var distanceLabels = [String]()
        for distance in distances {
            distanceLabels.append("\(distance) km")
        }
        sliderLabels.names = distanceLabels
        
        slider.ticksListener = sliderLabels
        
        slider.addTarget(self,
                         action: #selector(valueChanged(_:event:)),
                         for: .valueChanged)
        
        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpOutside)

    }
    
    func stopped(_ sender: TGPDiscreteSlider, event:UIEvent) {
        let value = Int(sender.value)
        sliderLabels.value = UInt(value)
        let distance = distances[value]
        print("DISTANCE SELECTED: \(distance)")
        LocationService.sharedInstance.radius = distance
        LocationService.sharedInstance.requestNearbyLocations()
    }
    
    func valueChanged(_ sender: TGPDiscreteSlider, event:UIEvent) {
        sliderLabels.value = UInt(sender.value)
    }
}

/*public func tgpTicksDistanceChanged(_ ticksDistance: CGFloat, sender: Any!)
 
 
 optional public func tgpValueChanged(_ value: UInt32)*/
