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
    
    @IBOutlet weak var typesLabel: UILabel!
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
        
        setupTypeLabel(withTypes: [])
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
    
    @IBAction func editTypesTapped(_ sender: UIButton) {
        print("Edit Types!")
        
        let controller = UIViewController()
        
        controller.view.backgroundColor = UIColor.red
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    
    func setupTypeLabel(withTypes types:[String]) {
        let prefix = "Types  "
        let str = "\(prefix)Gyms, Schools, Stores"
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular),
            NSForegroundColorAttributeName : UIColor(white: 0.6777, alpha: 1.0)
            ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        if let range = str.range(of: prefix) {// .rangeOfString(countStr) {
            let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightSemibold),
                NSForegroundColorAttributeName : UIColor.black
            ]
            title.addAttributes(a, range: NSRange(location: index, length: prefix.characters.count))
        }
        
        
        typesLabel.attributedText = title

    }
    
}

/*public func tgpTicksDistanceChanged(_ ticksDistance: CGFloat, sender: Any!)
 
 
 optional public func tgpValueChanged(_ value: UInt32)*/
