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
    
    fileprivate static let ref = Database.database().reference()
    
    fileprivate static var listeningToFollowers = false
    fileprivate static var listeningToFollowing = false
    fileprivate static var listeningToViewed = false
    
    fileprivate static var listenForForcedRefersh = false
    
    static func stopListeningToAll() {

        stopListeningToFollowers()
        stopListeningToFollowing()
        stopListeningToViewed()
        stopListeningForForcedRefresh()
    }
    
    static func startListeningForForcedRefresh() {
        let uid = mainStore.state.userState.uid
        let refreshRef = ref.child("operational/refresh/\(uid)")
        refreshRef.observe(.value, with: { snapshot in
            if snapshot.exists() {
                print("Force refresh")
                globalMainInterfaceProtocol?.fetchAllStories()
                refreshRef.removeValue()
            }
        })
    }
    
    static func stopListeningForForcedRefresh() {
        let uid = mainStore.state.userState.uid
        let refreshRef = ref.child("operational/refresh/\(uid)")
        refreshRef.removeAllObservers()
    }
    
   
    static func startListeningToFollowers() {
        print("START LISTENING TO FOLLOWERS")
        if !listeningToFollowers {
            listeningToFollowers = true
            let current_uid = mainStore.state.userState.uid
            let followersRef = ref.child("social/followers/\(current_uid)")
            
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
        print("START LISTENING TO FOLLOWING")
        if !listeningToFollowing {
            listeningToFollowing = true
            let current_uid = mainStore.state.userState.uid
            let followingRef = ref.child("/social/following/\(current_uid)")
            
            /**
             Listen for a Following Added
             */
            followingRef.observe(.childAdded, with: { snapshot in
                print("\n\nFAMMM!!\n\n")
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
        ref.child("social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowers = false
        print("STOP LISTENING TO FOLLOWERS")
    }
    
    static func stopListeningToFollowing() {
        let current_uid = mainStore.state.userState.uid
        ref.child("social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowing = false
        print("STOP LISTENING TO FOLLOWERING")
    }
    
    static func startListeningToViewed() {
        if !listeningToViewed {
            listeningToViewed = true
            let current_uid = mainStore.state.userState.uid
            
            let viewedRef = ref.child("users/viewed/\(current_uid)")
            viewedRef.observe(.value, with: { snapshot in
                var viewed = [String]()
                if snapshot.exists() {
                    
                    for postKey in snapshot.children {
                        let childSnap = postKey as! DataSnapshot
                        viewed.append(childSnap.key)
                    }
                }
                mainStore.dispatch(SetViewed(postKeys: viewed))
            })
        }
    }
    
    static func stopListeningToViewed() {
        let uid = mainStore.state.userState.uid
        let viewedRef = ref.child("users/viewed/\(uid)")
        viewedRef.removeAllObservers()
        listeningToViewed = false
    }
    
    
}
