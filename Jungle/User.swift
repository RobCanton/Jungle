//
//  User.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-10.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation


class Comment: NSObject {
    
    private(set) var key:String                    // Key in database
    private(set) var author:String
    private(set) var text:String
    private(set) var date:Date
    
    init(key:String, author:String, text:String, timestamp:Double)
    {
        self.key     = key
        self.author  = author
        self.text    = text
        self.date    = Date(timeIntervalSince1970: timestamp/1000)
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
    private(set) var uid: String
    private(set) var username: String
    private(set) var imageURL: String
    private(set) var bio: String
    private(set) var posts:Int
    private(set) var followers:Int
    private(set) var following:Int
    
    init(uid:String, username:String, imageURL:String, bio:String, posts:Int, followers:Int, following:Int)
    {
        self.uid       = uid
        self.username  = username
        self.imageURL  = imageURL
        self.bio       = bio
        self.posts     = posts
        self.followers = followers
        self.following = following
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let uid = decoder.decodeObject(forKey: "uid") as! String
        let username = decoder.decodeObject(forKey: "username") as! String
        let imageURL = decoder.decodeObject(forKey: "imageURL") as! String
        let bio = decoder.decodeObject(forKey: "bio") as! String
        let posts = decoder.decodeObject(forKey: "posts") as! Int
        let followers = decoder.decodeObject(forKey: "followers") as! Int
        let following = decoder.decodeObject(forKey: "following") as! Int
        self.init(uid: uid, username: username, imageURL: imageURL, bio: bio, posts: posts, followers: followers, following: following)

    }

    
    func encode(with coder: NSCoder) {
        coder.encode(uid, forKey: "uid")
        coder.encode(username, forKey: "username")
        coder.encode(imageURL, forKey: "imageURL")
        coder.encode(posts, forKey: "posts")
        coder.encode(followers, forKey: "followers")
        coder.encode(following, forKey: "following")
    }

}
