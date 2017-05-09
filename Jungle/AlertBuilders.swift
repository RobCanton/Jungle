//
//  AlertFactory.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-02.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import SwiftMessages

enum AlertType:String {
    case uploading = "uploading_alert"
    case upload_success = "upload_success_alert"
}

struct Alerts {

    static func showStatusSuccessAlert(inWrapper wrapper: SwiftMessages, withMessage message: String){
        wrapper.hideAll()
        
        let alert = MessageView.viewFromNib(layout: .StatusLine)
        alert.backgroundView.backgroundColor = UIColor.white
        alert.bodyLabel?.textColor = accentColor
        alert.configureContent(body: message)
        
        var config = SwiftMessages.defaultConfig
        config.duration = SwiftMessages.Duration.seconds(seconds: 2.0)
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        
        wrapper.show(config: config, view: alert)
    }
    
    static func showStatusFailAlert(inWrapper wrapper: SwiftMessages, withMessage message: String){
        wrapper.hideAll()
        
        let alert = MessageView.viewFromNib(layout: .StatusLine)
        alert.backgroundView.backgroundColor = errorColor
        alert.bodyLabel?.textColor = UIColor.white
        alert.configureContent(body: message)
        
        var config = SwiftMessages.defaultConfig
        config.duration = SwiftMessages.Duration.seconds(seconds: 3.0)
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        
        wrapper.show(config: config, view: alert)
    }
    
    static func showStatusProgressAlert(inWrapper wrapper: SwiftMessages, withMessage message: String){
        wrapper.hideAll()
        
        let alert = MessageView.viewFromNib(layout: .StatusLine)
        alert.backgroundView.backgroundColor = UIColor.black
        alert.bodyLabel?.textColor = UIColor.white
        alert.configureContent(body: message)
        
        var config = SwiftMessages.defaultConfig
        config.duration = .forever
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        
        wrapper.show(config: config, view: alert)
    }
    
    static func showStatusDefaultAlert(inWrapper wrapper: SwiftMessages, withMessage message: String){
        wrapper.hideAll()
        
        let alert = MessageView.viewFromNib(layout: .StatusLine)
        alert.backgroundView.backgroundColor = UIColor.white
        alert.bodyLabel?.textColor = UIColor.darkGray
        alert.configureContent(body: message)
        
        var config = SwiftMessages.defaultConfig
        config.duration = SwiftMessages.Duration.seconds(seconds: 2.0)
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        
        wrapper.show(config: config, view: alert)
    }
    
    
}
