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

    
    static func stopListeningToAll() {

        stopListeningToFollowers()
        stopListeningToFollowing()
        stopListeningToConversatons()
    }
    
   
    static func startListeningToFollowers() {
        if !listeningToFollowers {
            listeningToFollowers = true
            print("listeningToFollowers")
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
            print("listeningToFollowing")
            let current_uid = mainStore.state.userState.uid
            let followingRef = ref.child("users/social/following/\(current_uid)")
            
            /**
             Listen for a Following Added
             */
            followingRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    print("YEUH")
                    if snapshot.value! is Bool {
                        print("NOICE")
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
                        print("YEUHa")
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
    
    
    
}
