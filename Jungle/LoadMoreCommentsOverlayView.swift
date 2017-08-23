//
//  LoadMoreCommentsOverlayView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-19.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class LoadMoreCommentsOverlayView: UIView {
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backView.layer.borderColor = UIColor.white.cgColor
        backView.layer.borderWidth = 1.0
        backView.layer.cornerRadius = backView.frame.height / 2
        backView.clipsToBounds = true
        startLoadAnimation()

        
    }
    
    func delay() {
        print("DELAY!")
        self.alpha = 0.0
        
        UIView.animate(withDuration: 0.0, delay: 3.0, options: .curveLinear, animations: {
            
        }, completion: { _ in
            self.alpha = 1.0
            print("DELAY OVERRRRRRRR")
        })
    }
    
    func startLoadAnimation() {
        label.isHidden = true
        self.activityIndicator.startAnimating()
        backView.isHidden = true
        
    }
    
    func stopLoadAnimation() {
        label.isHidden = false
        self.activityIndicator.stopAnimating()
        backView.isHidden = false
    }
}
