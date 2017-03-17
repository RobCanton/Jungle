//
//  CommentBar.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit


class CommentBar: UIView {
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var commentPlaceHolder: UILabel!
    
    
    @IBOutlet weak var sendButton: UIButton!
    
    var sendHandler:((_ text:String)->())?


    override func awakeFromNib() {
        
        textField.autocapitalizationType = .sentences
        textField.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
        sendButton.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
    }
    
    @IBAction func sendButton(_ sender: Any) {
        if let text = textField.text {
            textField.text = ""
            sendHandler?(text)
        }

    }
    
}
