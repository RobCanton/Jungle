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

class SortOptionsView: UIView {
    
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var slider: TGPDiscreteSlider!
    @IBOutlet weak var sliderLabels: TGPCamelLabels!
    
    @IBOutlet weak var setButton: UIButton!
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
        
        backgroundView.layer.cornerRadius = 8.0
        backgroundView.clipsToBounds = true
        
        setButton.layer.cornerRadius = 6.0
        setButton.clipsToBounds = true
    }
    
    
    func stopped(_ sender: TGPDiscreteSlider, event:UIEvent) {
        let value = Int(sender.value)
        sliderLabels?.value = UInt(value)
    }

    func valueChanged(_ sender: TGPDiscreteSlider, event:UIEvent) {
        sliderLabels?.value = UInt(sender.value)
    }
    
    
    @IBAction func handleSet(_ sender: Any) {
        let value = Int(slider.value)

        let distance = distances[value]
        LocationService.sharedInstance.radius = distance
        LocationService.sharedInstance.requestNearbyLocations()
    }

}

/*public func tgpTicksDistanceChanged(_ ticksDistance: CGFloat, sender: Any!)
 
 
 optional public func tgpValueChanged(_ value: UInt32)*/
