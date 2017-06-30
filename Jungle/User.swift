//
//  User.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-10.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation



class User:NSObject, NSCoding {
    private(set) var uid: String
    private(set) var username: String
    private(set) var firstname: String
    private(set) var lastname: String
    private(set) var imageURL: String
    private(set) var bio: String
    private(set) var posts:Int
    private(set) var followers:Int
    private(set) var following:Int
    
    var fullname:String {
        get {
            if lastname != "" {
                return "\(firstname) \(lastname)"
            } else {
                return firstname
            }
        }
    }
    
    init(uid:String, username:String, firstname:String, lastname:String, imageURL:String, bio:String, posts:Int, followers:Int, following:Int)
    {
        self.uid       = uid
        self.username  = username
        self.firstname  = firstname
        self.lastname  = lastname
        self.imageURL  = imageURL
        self.bio       = bio
        self.posts     = posts
        self.followers = followers
        self.following = following
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let uid = decoder.decodeObject(forKey: "uid") as! String
        let username = decoder.decodeObject(forKey: "username") as! String
        let firstname = decoder.decodeObject(forKey: "firstname") as! String
        let lastname = decoder.decodeObject(forKey: "lastname") as! String
        let imageURL = decoder.decodeObject(forKey: "imageURL") as! String
        let bio = decoder.decodeObject(forKey: "bio") as! String
        let posts = decoder.decodeObject(forKey: "posts") as! Int
        let followers = decoder.decodeObject(forKey: "followers") as! Int
        let following = decoder.decodeObject(forKey: "following") as! Int
        self.init(uid: uid, username: username, firstname: firstname, lastname: lastname, imageURL: imageURL, bio: bio, posts: posts, followers: followers, following: following)

    }

    
    func encode(with coder: NSCoder) {
        coder.encode(uid, forKey: "uid")
        coder.encode(username, forKey: "username")
        coder.encode(firstname, forKey: "firstname")
        coder.encode(lastname, forKey: "lastname")
        coder.encode(imageURL, forKey: "imageURL")
        coder.encode(posts, forKey: "posts")
        coder.encode(followers, forKey: "followers")
        coder.encode(following, forKey: "following")
    }
    
    

}
