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
    func itemStateDidChange(comments:[Comment])
    func itemStateDidChange(subscribed:Bool)
}

class ItemStateController {
    
    weak var item:StoryItem?
    weak var delegate:ItemStateProtocol?
    var likedRef:DatabaseReference?
    var numLikesRef:DatabaseReference?
    var commentsRef:DatabaseReference?
    var subscribedRef:DatabaseReference?
    
    func setupItem(_ item:StoryItem) {
        self.item = item
        if item.needsDownload() {
            download()
        } else {
            itemDownloaded()
        }
        
        observeLikeStatus()
        observeNumLikes()
        observeComments()
        
        observeSubscribeStatus()
    }
    
    func download() {
        guard let item = self.item else { return }
        delegate?.itemDownloading()
        UploadService.retrievePostImageVideo(post: item) { post in
            if post.key != item.key { return }
            self.delegate?.itemDownloaded()
        }
    }
    
    func itemDownloaded() {
        delegate?.itemDownloaded()
        observeLikeStatus()
        observeNumLikes()
        observeComments()
        observeSubscribeStatus()
    }
    
    func removeAllObservers() {
        item = nil
        likedRef?.removeAllObservers()
        numLikesRef?.removeAllObservers()
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
        numLikesRef = Database.database().reference().child("uploads/meta/\(item.key)/likes")
        numLikesRef!.observe(.value, with: { snapshot in
            var count = 0
            if let _count = snapshot.value as? Int {
                count = _count
            }
            item.numLikes = count
            self.delegate?.itemStateDidChange(numLikes: count)
            
        })
    }
    
    func observeComments() {
        guard let item = self.item else { return }
        
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/comments/\(item.key)")
        
        if let lastItem = item.comments.last {
            let lastKey = lastItem.key
            let ts = lastItem.date.timeIntervalSince1970 * 1000
            commentsRef?.queryOrdered(byChild: "timestamp").queryStarting(atValue: ts).observe(.childAdded, with: { snapshot in
                
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                if key != lastKey {
                    let author = dict["author"] as! String
                    let text = dict["text"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                    item.addComment(comment)
                    self.delegate?.itemStateDidChange(comments: item.comments)
                }
            })
        } else {
            commentsRef?.observe(.childAdded, with: { snapshot in
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                let author = dict["author"] as! String
                let text = dict["text"] as! String
                let timestamp = dict["timestamp"] as! Double
                let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                item.addComment(comment)
                self.delegate?.itemStateDidChange(comments: item.comments)
            })
        }
    }
    
    func observeSubscribeStatus() {
        guard let item = self.item else { return }
        let uid = mainStore.state.userState.uid
        
        subscribedRef?.removeAllObservers()
        subscribedRef = UserService.ref.child("uploads/subscribers/\(item.key)/\(uid)")
        subscribedRef?.observe(.value, with: { snapshot in
            self.delegate?.itemStateDidChange(subscribed: snapshot.exists())
        })
    }
    
    
}
