//
//  Listeners.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-20.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import Firebase


class Listeners {
    
    fileprivate static let ref = FIRDatabase.database().reference()
    
    fileprivate static var listeningToFollowers = false
    fileprivate static var listeningToFollowing = false
    fileprivate static var listeningToConversations = false
    fileprivate static var listeningToNotifications = false

    
    static func stopListeningToAll() {

        stopListeningToFollowers()
        stopListeningToFollowing()
        stopListeningToConversatons()
        stopListeningToNotifications()
    }
    
   
    static func startListeningToFollowers() {
        if !listeningToFollowers {
            listeningToFollowers = true
            let current_uid = mainStore.state.userState.uid
            let followersRef = ref.child("users/social/followers/\(current_uid)")
            
            /** Listen for a Follower Added */
            followersRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(AddFollower(uid: snapshot.key))
                    }
                }
            })
            
            
            /** Listen for a Follower Removed */
            followersRef.observe(.childRemoved, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(RemoveFollower(uid: snapshot.key))
                    }
                }
            })
        }
    }
    
    static func startListeningToFollowing() {
        if !listeningToFollowing {
            listeningToFollowing = true
            let current_uid = mainStore.state.userState.uid
            let followingRef = ref.child("users/social/following/\(current_uid)")
            
            /**
             Listen for a Following Added
             */
            followingRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(AddFollowing(uid: snapshot.key))
                    }
                    
                }
            })
            
            
            /**
             Listen for a Following Removed
             */
            followingRef.observe(.childRemoved, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(RemoveFollowing(uid: snapshot.key))
                    }
                }
            })
            
        }
    }
    
    static func stopListeningToFollowers() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowers = false
    }
    
    static func stopListeningToFollowing() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowing = false
    }
    
    static func startListeningToConversations() {
        if !listeningToConversations {
            listeningToConversations = true
            
            let uid = mainStore.state.userState.uid
            let conversationsRef = ref.child("users/conversations/\(uid)")
            conversationsRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    
                    let partner = snapshot.key
                    let pairKey = createUserIdPairKey(uid1: uid, uid2: partner)
                    let listening = snapshot.value! as! Bool
                    let conversation = Conversation(key: pairKey, partner_uid: partner, listening: listening)
                    mainStore.dispatch(ConversationAdded(conversation: conversation))
                }
            })
        }
    }
    
    static func stopListeningToConversatons() {
        let uid = mainStore.state.userState.uid
        let conversationsRef = ref.child("users/conversations/\(uid)")
        conversationsRef.removeAllObservers()
        listeningToConversations = false
    }
    
    static func startListeningToNotifications() {
        if !listeningToNotifications {
            listeningToNotifications = true
            let current_uid = mainStore.state.userState.uid
            let notificationsRef = ref.child("notifications/\(current_uid)")
            notificationsRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    let key          = snapshot.key
                    let dict         = snapshot.value as! [String:AnyObject]
                    let sender       = dict["sender"] as! String
                    let timestamp    = dict["timestamp"] as! Double
                    let type         = dict["type"] as! String
                    let seen         = dict["seen"] as! Bool
                    let postKey      = dict["postKey"] as? String
                    let date         = Date(timeIntervalSince1970: timestamp/1000)
                    let notification = Notification(key: key, type: type, date: date, sender: sender, seen: seen, postKey: postKey)
                    mainStore.dispatch(AddNotification(notification: notification))
                }
            })
        }
    }
    
    static func stopListeningToNotifications() {
        let uid = mainStore.state.userState.uid
        let notificationsRef = ref.child("notifications/\(uid)")
        notificationsRef.removeAllObservers()
        listeningToNotifications = false
    }
    
    
}
