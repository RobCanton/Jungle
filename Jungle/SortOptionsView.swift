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

protocol SortOptionsProtocol:class {
    func dismissSortOptions()
}

class SortOptionsView: UIView {
    
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var slider: TGPDiscreteSlider!
    @IBOutlet weak var sliderLabels: TGPCamelLabels!
    
    @IBOutlet weak var setButton: UIButton!
    
    
    weak var delegate:SortOptionsProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        var distanceLabels = [String]()
        let selectedDistance = LocationService.sharedInstance.radius
        
        var selectedIndex = 4
        var count = 0
        for range in Config.ranges {
            distanceLabels.append(range.label)
            if range.distance == selectedDistance {
                selectedIndex = count
            }
            count += 1
        }
        
        slider.tickCount = Config.ranges.count
        sliderLabels?.value = UInt(selectedIndex)
        slider.value = CGFloat(selectedIndex)
        
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
        let value = Int(slider.value)
        sliderLabels?.value = UInt(sender.value)
        activateSetButtton(Config.ranges[value].distance != LocationService.sharedInstance.radius)
    }
    
    func activateSetButtton(_ activate:Bool) {
        if activate {
            setButton.backgroundColor = accentColor
            setButton.isEnabled = true
        } else {
            setButton.backgroundColor = UIColor.lightGray
            setButton.isEnabled = false
        }
    }
    
    
    @IBAction func handleSet(_ sender: Any) {
        let value = Int(slider.value)

        let distance = Config.ranges[value].distance
        LocationService.sharedInstance.setSearchRadius(distance)
        
        
        delegate?.dismissSortOptions()
    }

    @IBAction func handleDismiss(_ sender: Any) {
        delegate?.dismissSortOptions()
    }
}

/*public func tgpTicksDistanceChanged(_ ticksDistance: CGFloat, sender: Any!)
 
 
 optional public func tgpValueChanged(_ value: UInt32)*/
