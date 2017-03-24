//
//  ProfileTabHeader.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-23.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class ProfileTabHeader: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    @IBAction func handleSettings(_ sender: Any) {
        print("YEH")
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsContainerViewController")
        globalMainRef?.navigationController?.delegate = nil
        globalMainRef?.activateNavbar(true)
        globalMainRef?.navigationController?.pushViewController(controller, animated: true)
        
    }

}
