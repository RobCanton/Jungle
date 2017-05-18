//
//  EmptyCollectionHeader.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-11.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class EmptyCollectionHeader: UICollectionReusableView {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    func tapped() {
        globalMainInterfaceProtocol?.presentCamera()
    }
    
}
