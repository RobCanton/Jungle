//
//  CommentBar.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

protocol CommentBarProtocol: class {
    func sendComment(_ text:String)
}

class CommentBar: UIView {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate:CommentBarProtocol?

    override func awakeFromNib() {
        //commentPlaceHolder.textColor = UIColor(white: 0.5, alpha: 1.0)
        textField.autocapitalizationType = .sentences
        //textField.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
        //sendButton.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
    }
    
    @IBAction func sendButton(_ sender: Any) {
        if let text = textField.text {
            textField.text = ""
            delegate?.sendComment(text)
        }

    }
    
    func sendLabelState(_ active:Bool) {
        if active {
            sendButton.setTitleColor(accentColor, for: .normal)
        } else {
            sendButton.setTitleColor(UIColor(white: 0.5, alpha: 1.0), for: .normal)
        }
    }
    
}
