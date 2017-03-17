//
//  User.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-10.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation


class Comment: NSObject {
    
    fileprivate var key:String                    // Key in database
    fileprivate var author:String
    fileprivate var text:String
    fileprivate var date:Date
    
    init(key:String, author:String, text:String, timestamp:Double)
    {
        self.key          = key
        self.author       = author
        self.text         = text
        self.date    = Date(timeIntervalSince1970: timestamp/1000)
    }
    
    /* Getters */
    
    func getKey() -> String
    {
        return key
    }
    
    func getAuthor()-> String
    {
        return author
    }
    
    func getText() -> String
    {
        return text
    }
    
    func getDate() -> Date
    {
        return date
    }
}

func < (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

func > (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedDescending
}

func == (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedSame
}

class User:NSObject, NSCoding {
    fileprivate var uid: String
    fileprivate var username: String
    fileprivate var imageURL: String
    
    init(uid:String, username:String, imageURL:String)
    {
        self.uid       = uid
        self.username  = username
        self.imageURL  = imageURL
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let uid = decoder.decodeObject(forKey: "uid") as! String
        let username = decoder.decodeObject(forKey: "username") as! String
        let imageURL = decoder.decodeObject(forKey: "imageURL") as! String
        self.init(uid: uid, username: username, imageURL: imageURL)

    }

    
    func encode(with coder: NSCoder) {
        coder.encode(uid, forKey: "uid")
        coder.encode(username, forKey: "username")
        coder.encode(imageURL, forKey: "imageURL")
    }
    

    
    func getUserId() -> String {
        return uid
    }
    
    func getUsername() -> String {
        return username
    }
    

    func getImageUrl() -> String {
        return imageURL
    }
    
    
}
