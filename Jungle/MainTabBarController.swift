//
//  MainTabBarController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-19.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false
        self.edgesForExtendedLayout = []
        
        
        
    }
    
}


class temp:UIViewController {
    
    var backDrop:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = []
        
        self.view.backgroundColor = UIColor.clear
        backDrop = UIView(frame: self.view.bounds)
        backDrop.backgroundColor = UIColor.white
        
        backDrop.layer.cornerRadius = 16.0
        backDrop.clipsToBounds = true
        
        self.view.addSubview(backDrop)
        
    

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
