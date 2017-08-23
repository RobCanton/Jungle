//
//  ItemStateController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-11.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol ItemStateProtocol: class {
    
    func itemDownloading()
    func itemDownloaded()
    func itemStateDidChange(likedStatus:Bool)
    func itemStateDidChange(numLikes:Int)
    func itemStateDidChange(numComments:Int)
    func itemStateDidChange(comments:[Comment])
    func itemStateDidChange(comments:[Comment], didRetrievePreviousComments: Bool)
    func itemStateDidChange(subscribed:Bool)
}

class ItemStateController {
    
    weak var item:StoryItem?
    weak var delegate:ItemStateProtocol?
    var likedRef:DatabaseReference?
    var numLikesRef:DatabaseReference?
    var commentsRef:DatabaseReference?
    var numCommentsRef:DatabaseReference?
    var subscribedRef:DatabaseReference?
    
    var isSubscribed = false
    var limit:UInt = 16
    
    func setupItem(_ item:StoryItem) {
        self.item = item
        if item.needsDownload() {
            download()
        } else {
            itemDownloaded()
        }

        
        observeLikeStatus()
        observeNumLikes()
        observeNumComments()
        observeComments()
        
        observeSubscribeStatus()
    }
    
    func download() {
        guard let item = self.item else { return }
        delegate?.itemDownloading()
        UploadService.retrievePostImageVideo(post: item) { post in
            guard let _item = self.item else { return }
            if post.key != _item.key { return }
            self.itemDownloaded()
        }
    }
    
    func itemDownloaded() {
        delegate?.itemDownloaded()
        observeLikeStatus()
        observeNumLikes()
        observeComments()
        observeSubscribeStatus()
        observeNumComments()
    }
    
    func removeAllObservers() {
        //item = nil
        isSubscribed = false
        limit = 16
        likedRef?.removeAllObservers()
        numLikesRef?.removeAllObservers()
        numCommentsRef?.removeAllObservers()
        commentsRef?.removeAllObservers()
        subscribedRef?.removeAllObservers()
    }
    
    func observeLikeStatus() {
        guard let item = self.item else { return }
        let uid = mainStore.state.userState.uid
        likedRef?.removeAllObservers()
        likedRef = Database.database().reference().child("uploads/likes/\(item.key)/\(uid)")
        likedRef!.observe(.value, with: { snapshot in
            self.delegate?.itemStateDidChange(likedStatus: snapshot.exists())
        })
        
    }
    
    
    func observeNumLikes() {
        guard let item = self.item else { return }
        let uid = mainStore.state.userState.uid
        numLikesRef?.removeAllObservers()
        numLikesRef = Database.database().reference().child("uploads/meta/\(item.key)/stats/likes")
        numLikesRef!.observe(.value, with: { snapshot in
            var count = 0
            if let _count = snapshot.value as? Int {
                count = _count
            }
            item.numLikes = count
            self.delegate?.itemStateDidChange(numLikes: count)
            
        })
    }
    
    func observeNumComments() {
        guard let item = self.item else { return }
        let uid = mainStore.state.userState.uid
        numCommentsRef?.removeAllObservers()
        numCommentsRef = Database.database().reference().child("uploads/meta/\(item.key)/stats/comments")
        numCommentsRef!.observe(.value, with: { snapshot in
            var count = 0
            if let _count = snapshot.value as? Int {
                count = _count
            }
            item.numComments = count
            self.delegate?.itemStateDidChange(numComments: count)
            
        })
    }
    
    func observeComments() {
        guard let item = self.item else { return }
        //self.delegate?.itemStateDidChange(comments: item.comments)
        
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/comments/\(item.key)")

        commentsRef?.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit).observe(.childAdded, with: { snapshot in

            let key = snapshot.key
            if let dict = snapshot.value as? [String:Any],
                let author = dict["author"] as? String,
                let timestamp = dict["timestamp"] as? Double,
                let text = dict["text"] as? String
            {
                var numLikes = 0
                if let likes = dict["likes"] as? Int {
                    numLikes = likes
                }
                
                if let anon = dict["anon"] as? [String:Any] {
                    if let adjective = anon["adjective"] as? String,
                        let animal = anon["animal"] as? String,
                        let color = anon["color"] as? String {
                        let comment = AnonymousComment(key: key, author: author, text: text, timestamp: timestamp, numLikes:numLikes, adjective: adjective, animal: animal, colorHexcode: color)
                        item.addComment(comment)
                    }
                    self.delegate?.itemStateDidChange(comments: item.comments)
                } else {
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp, numLikes: numLikes)
                    item.addComment(comment)
                    self.delegate?.itemStateDidChange(comments: item.comments)
                }
            
            }
            
            
        })

    }
    

    
    func retrievePreviousComments() {
        guard let item = self.item else { return }
        let comments = item.comments
        let oldestComment = comments[0]
        let date = oldestComment.date
        let endTimestamp = date.timeIntervalSince1970 * 1000
        
        commentsRef?.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit).queryEnding(atValue: endTimestamp).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var commentBatch = [Comment]()
                
                for commentChild in snapshot.children {
                    let commentSnap = commentChild as! DataSnapshot
                    if let dict = commentSnap.value as? [String:Any],
                        let author = dict["author"] as? String,
                        let timestamp = dict["timestamp"] as? Double,
                        let text = dict["text"] as? String
                    {
                       
                        var numLikes = 0
                        if let likes = dict["likes"] as? Int {
                            numLikes = likes
                        }
                        
                        if timestamp != endTimestamp {
                            let key = commentSnap.key
                            
                            if let anon = dict["anon"] as? [String:Any] {
                                if let adjective = anon["adjective"] as? String,
                                    let animal = anon["animal"] as? String,
                                    let color = anon["color"] as? String {
                                    let comment = AnonymousComment(key: key, author: author, text: text, timestamp: timestamp, numLikes:numLikes, adjective: adjective, animal: animal, colorHexcode: color)
                                    commentBatch.append(comment)
                                }
                            } else {
                                let comment = Comment(key: key, author: author, text: text, timestamp: timestamp, numLikes:numLikes)
                                commentBatch.append(comment)
                            }
                            
                            
                        }
                        
                    }
                    
                    
                }
                
                if commentBatch.count > 0 {
                    item.comments.insert(contentsOf: commentBatch, at: 0)
                    self.delegate?.itemStateDidChange(comments: item.comments, didRetrievePreviousComments: true)
                } else {
                    self.delegate?.itemStateDidChange(comments: item.comments, didRetrievePreviousComments: false)
                }
            } else {
                self.delegate?.itemStateDidChange(comments: item.comments, didRetrievePreviousComments: false)
            }
        })
    }
    
    func observeSubscribeStatus() {
        guard let item = self.item else { return }
        let uid = mainStore.state.userState.uid
        
        subscribedRef?.removeAllObservers()
        subscribedRef = UserService.ref.child("uploads/subscribers/\(item.key)/\(uid)")
        subscribedRef?.observe(.value, with: { snapshot in
            self.isSubscribed = snapshot.exists()
            self.delegate?.itemStateDidChange(subscribed: self.isSubscribed)
        })
    }
    
    
}
