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
    
    
    @IBOutlet weak var anonLabel: UILabel!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var slider: TGPDiscreteSlider!
    @IBOutlet weak var sliderLabels: TGPCamelLabels!
    
    
    @IBOutlet weak var anonSwitch: UISwitch!
    
    weak var delegate:SortOptionsProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        anonLabel.setKerning(withText: "ANONYMOUS", 1.15)
        radiusLabel.setKerning(withText: "SEARCH RADIUS", 1.15)
        
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
        
        userImageView.cropToCircle()
        
        anonSwitch.setOn(!userState.anonMode, animated: false)
        handleAnonSwitch(anonSwitch)
    }
    
    
    
    func stopped(_ sender: TGPDiscreteSlider, event:UIEvent) {
        let value = Int(sender.value)
        sliderLabels?.value = UInt(value)
        let distance = Config.ranges[value].distance
        LocationService.sharedInstance.setSearchRadius(distance)
        print("Range changed")
    }

    func valueChanged(_ sender: TGPDiscreteSlider, event:UIEvent) {
        let value = Int(slider.value)
        sliderLabels?.value = UInt(sender.value)
        print("valueChanged")
    }
    

    
    
//    @IBAction func handleSet(_ sender: Any) {
//        let value = Int(slider.value)
//
//        let distance = Config.ranges[value].distance
//        LocationService.sharedInstance.setSearchRadius(distance)
//        
//        
//        delegate?.dismissSortOptions()
//    }

    @IBAction func handleDismiss(_ sender: Any) {
        delegate?.dismissSortOptions()
    }
    @IBAction func handleAnonSwitch(_ sender: Any) {
        if !anonSwitch.isOn {
            mainStore.dispatch(GoAnonymous())
            setTitleLabel(prefix: "Use ", username: "anonymously", highlightColor: accentColor)
            userImageView.image = UIImage(named: "private2")
            userImageView.backgroundColor = accentColor
            userImageView.layer.borderColor = accentColor.cgColor
            userImageView.layer.borderWidth = 2.0
        } else {
            
            mainStore.dispatch(GoPublic())
            userImageView.layer.borderColor = infoColor.cgColor
            if let user = userState.user {
                setTitleLabel(prefix: "Use as ", username: "@\(user.username)", highlightColor: infoColor)
                userImageView.loadImageAsync(user.imageURL, completion: nil)
            } else {
                usernameLabel.text = "User not found!"
                userImageView.image = nil
            }
            
        }
    }
    
    func setTitleLabel(prefix:String, username:String, highlightColor:UIColor) {
        let str = "\(prefix)\(username)"
        let attributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: highlightColor,
            NSFontAttributeName : UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        let a: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor.darkGray,
            NSFontAttributeName : UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular),
            ]
        title.addAttributes(a, range: NSRange(location: 0, length: prefix.characters.count))
        
        usernameLabel.attributedText = title
        
    }
}

/*public func tgpTicksDistanceChanged(_ ticksDistance: CGFloat, sender: Any!)
 
 
 optional public func tgpValueChanged(_ value: UInt32)*/
