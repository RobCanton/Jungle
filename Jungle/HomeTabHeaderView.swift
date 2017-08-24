//
//  HomeTabHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-23.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

enum HomeMode {
    case home, popular
}

protocol HomeTabHeaderProtocol:class {
    func modeChange(_ mode:HomeMode)
    func showSortOptions()
}

class HomeTabHeaderView:UIView {
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var popularButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    
    weak var delegate:HomeTabHeaderProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var slider:UIView!
    var anonButton:UIButton!
    
    func setup() {
        let sliderHeight:CGFloat = 2.0
        slider?.removeFromSuperview()
        slider = UIView(frame: CGRect(x: 0, y: controlView.frame.height - sliderHeight, width: controlView.frame.width / 2, height: sliderHeight))
        slider.backgroundColor = accentColor
        controlView.insertSubview(slider, at: 0)
        
        anonButton = UIButton(frame: CGRect(x: 6.0, y: 6.0, width: 32.0, height: 32.0))
        anonButton.setImage(UIImage(named: "private2"), for: .normal)
        anonButton.layer.cornerRadius = anonButton.frame.height / 2
        anonButton.clipsToBounds = true
        anonButton.backgroundColor = accentColor
        anonButton.addTarget(self, action: #selector(switchAnonMode), for: .touchUpInside)
        
        self.addSubview(anonButton)
        showCurrentAnonMode()
        
    }
    
    @IBAction func homeButtonTapped(_ sender: Any) {
        setState(.home)
        delegate?.modeChange(.home)
    }
    
    @IBAction func popularButtonTapped(_ sender: Any) {
        setState(.popular)
        delegate?.modeChange(.popular)
    }
    
    @IBAction func sortOptionsTapped(_ sender: Any) {
        delegate?.showSortOptions()
    }
    
    func setState(_ mode:HomeMode) {
        switch mode {
        case .home:
            homeButton.isEnabled = false
            popularButton.isEnabled = true
            sortButton.isEnabled = true
            break
        case .popular:
            
            homeButton.isEnabled = true
            popularButton.isEnabled = false
            sortButton.isEnabled = false
            break
        }
    }
    
    func setSliderPos(_ percent:CGFloat) {
        var sliderFrame = slider.frame
        sliderFrame.origin.x = (sliderFrame.width) * percent
        slider.frame = sliderFrame
        sortButton.alpha = 1.0 - percent
        
    }
    
    func switchAnonMode() {
        
        mainStore.dispatch(ToggleAnonMode())
        if userState.anonMode {
            Alerts.showStatusAnonAlert(inWrapper: nil)
        } else {
            Alerts.showStatusPublicAlert(inWrapper: nil)
        }
    }
    
    func showCurrentAnonMode() {
        let isAnon = mainStore.state.userState.anonMode
        if isAnon {
            
            anonButton.setImage(UIImage(named:"private2"), for: .normal)
            anonButton.backgroundColor = accentColor
            
            
        } else {
            guard let user = mainStore.state.userState.user else {
                return
            }
            anonButton.setImage(nil, for: .normal)
            loadImageCheckingCache(withUrl: user.imageURL, check: 0, completion: { image, fromFile, check in
                if image != nil && !userState.anonMode{
                    self.anonButton.setImage(image!, for: .normal)
                }
            })
            
            anonButton.backgroundColor = infoColor
            
            
        }
    }
    
}
