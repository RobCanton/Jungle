//
//  PostEditOptionsBar.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-27.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

protocol EditOptionsBarProtocol:class {
    func editCancel()
    func editLocation()
    func editCaption()
}

class PostEditOptionsBar: UIView {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var locationBubble: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var captionButton: UIButton!

    weak var delegate: EditOptionsBarProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        locationBubble.layer.borderColor = UIColor.white.cgColor
        locationBubble.layer.borderWidth = 1.0
        
        locationBubble.layer.cornerRadius = locationBubble.bounds.height / 2
        locationBubble.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(editLocation))
        locationBubble.addGestureRecognizer(tap)
        locationBubble.isUserInteractionEnabled = true
        
    }
    
    
    @IBAction func handleCancel(_ sender: Any) {
        delegate?.editCancel()
    }
    
    func editLocation(_ press:UILongPressGestureRecognizer) {
        
        delegate?.editLocation()
        
    }

    @IBAction func handleCaption(_ sender: Any) {
        delegate?.editCaption()
    }
}
