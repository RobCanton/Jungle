//
//  LoadMoreTableView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-14.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class LoadMoreTableView: UITableViewHeaderFooterView {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    func startLoadAnimation() {
        label.isHidden = true
        self.activityIndicator.startAnimating()
        
    }
    
    func stopLoadAnimation() {
        label.isHidden = false
        self.activityIndicator.stopAnimating()
    }

}
