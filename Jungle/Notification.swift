//
//  Notification.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//


import Foundation
import UIKit

enum NotificationType:String {
    case comment = "COMMENT"
    case comment_also = "COMMENT_ALSO"
    case comment_to_sub = "COMMENT_TO_SUB"
    case follow  = "FOLLOW"
    case like    = "LIKE"
    case mention = "MENTION"
    case badge = "BADGE"
    case none  = "NONE"
}


class Notification: NSObject {
    
    private(set) var key:String                    // Key in database
    private(set) var type:NotificationType
    private(set) var date:Date
    private(set) var sender:String
    private(set) var postKey:String?
    private(set) var text:String?
    private(set) var count:Int?
    
    
    init(key:String, type:String, date:Date, sender:String, postKey:String?, text:String?, count:Int?)
    {
        self.key          = key
        switch type {
        case NotificationType.comment.rawValue:
            self.type = .comment
            break
        case NotificationType.comment_also.rawValue:
            self.type = .comment_also
            break
        case NotificationType.comment_to_sub.rawValue:
            self.type = .comment_to_sub
            break
        case NotificationType.follow.rawValue:
            self.type = .follow
            break
        case NotificationType.like.rawValue:
            self.type = .like
            break
        case NotificationType.mention.rawValue:
            self.type = .mention
            break
        case NotificationType.badge.rawValue:
            self.type = .badge
        default:
            self.type = .none
            break
        }
        
        self.date = date
        self.sender = sender
        self.postKey = postKey
        self.text = text
        self.count = count
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObject(forKey: "key") as! String
        let type = decoder.decodeObject(forKey: "type") as! String
        let date = decoder.decodeObject(forKey: "date") as! Date
        let sender = decoder.decodeObject(forKey: "sender") as! String
        let postKey = decoder.decodeObject(forKey: "postKey") as? String
        let text = decoder.decodeObject(forKey: "text") as? String
        let count = decoder.decodeObject(forKey: "count") as? Int
        self.init(key: key, type: type, date: date, sender: sender, postKey: postKey, text: text, count: count)
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(date, forKey: "date")
        coder.encode(sender, forKey: "sender")
        coder.encode(postKey, forKey: "postKey")
        coder.encode(text, forKey: "text")
        coder.encode(count, forKey: "count")
    }
}

func < (lhs: Notification, rhs: Notification) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

func > (lhs: Notification, rhs: Notification) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedDescending
}

func == (lhs: Notification, rhs: Notification) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedSame
}

class AnonymousNotification: Notification {
    
    private(set) var adjective:String
    private(set) var animal:String
    private(set) var colorHexcode:String
    var anonName:String {
        get {
            return "\(adjective)\(animal)"
        }
    }
    
    var color:UIColor {
        get {
            return hexStringToUIColor(hex: colorHexcode)
        }
    }
    
    init(key: String, type: String, date: Date, sender: String, postKey: String?, text: String?, count: Int?, adjective: String, animal:String, colorHexcode:String) {
        self.adjective = adjective
        self.animal = animal
        self.colorHexcode = colorHexcode
        super.init(key: key, type: type, date: date, sender: sender, postKey: postKey, text: text, count: count)
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObject(forKey: "key") as! String
        let type = decoder.decodeObject(forKey: "type") as! String
        let date = decoder.decodeObject(forKey: "date") as! Date
        let sender = decoder.decodeObject(forKey: "sender") as! String
        let postKey = decoder.decodeObject(forKey: "postKey") as? String
        let text = decoder.decodeObject(forKey: "text") as? String
        let count = decoder.decodeObject(forKey: "count") as? Int
        let adjective = decoder.decodeObject(forKey: "adjective") as! String
        let animal = decoder.decodeObject(forKey: "animal") as! String
        let colorHexcode = decoder.decodeObject(forKey: "colorHexcode") as! String
        self.init(key: key, type: type, date: date, sender: sender, postKey: postKey, text: text, count: count, adjective: adjective, animal:animal, colorHexcode: colorHexcode)
    }
    
    
    override func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(date, forKey: "date")
        coder.encode(sender, forKey: "sender")
        coder.encode(postKey, forKey: "postKey")
        coder.encode(text, forKey: "text")
        coder.encode(count, forKey: "count")
        coder.encode(adjective, forKey: "adjective")
        coder.encode(animal, forKey: "animal")
        coder.encode(colorHexcode, forKey: "colorHexcode")
    }
    
}
