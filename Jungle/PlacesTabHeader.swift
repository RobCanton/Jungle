//
//  PlacesTabHeader.swift
//  Jungle
//
//  Created by Robert Canton on 2017-04-04.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class PlacesTabHeader: UIView {

    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var sortinButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var refreshHandler:(()->())?
    var sortHandler:(()->())?
    
    

    @IBAction func handleRefresh(_ sender: Any) {
        startRefreshing()
        globalMainInterfaceProtocol?.fetchAllStories()
    }

    @IBAction func handleSort(_ sender: Any) {
        sortHandler?()
    }
    
    func startRefreshing() {
        refreshButton.isHidden = true
        activityIndicator.startAnimating()
    }
    
    func stopRefreshing() {
        refreshButton.isHidden = false
        activityIndicator.stopAnimating()
    }

}
