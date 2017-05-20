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
    fileprivate static var listeningToMyActivity = false
    fileprivate static var listeningToNearbyActivity = false
    fileprivate static var listeningToFollowingActivity = false
    fileprivate static var listeningToViewed = false
    
    fileprivate static var listenForForcedRefersh = false
    
    static func stopListeningToAll() {

        stopListeningToFollowers()
        stopListeningToFollowing()
        stopListeningToConversatons()
        stopListeningToNotifications()
        stopListeningToMyActivity()
        stopListeningToNearbyActivity()
        stopListeningToFollowingActivity()
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
    
    static func startListeningToConversations() {
        if !listeningToConversations {
            listeningToConversations = true
            
            let uid = mainStore.state.userState.uid
            let conversationsRef = ref.child("users/conversations/\(uid)")
            conversationsRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    
                    let partner = snapshot.key
                    let pairKey = createUserIdPairKey(uid1: uid, uid2: partner)
                    if let dict = snapshot.value as? [String:AnyObject]{
                        
                        if dict["blocked"] != nil {
                            mainStore.dispatch(ConversationRemoved(conversationKey: pairKey))
                        } else {
                            let seen = dict["seen"] as! Bool
                            let lastMessage = dict["text"] as! String
                            let timestamp = dict["latest"] as! Double
                            let date = Date(timeIntervalSince1970: timestamp/1000) as Date
                            let listening = true
                            
                            let conversation = Conversation(key: pairKey, partner_uid: partner, seen: seen, date: date, lastMessage: lastMessage, listening: listening)
                            mainStore.dispatch(ConversationAdded(conversation: conversation))
                        }
                    }
                }
            })
            
            conversationsRef.observe(.childChanged, with: { snapshot in
                if snapshot.exists() {
                    
                    let partner = snapshot.key
                    let pairKey = createUserIdPairKey(uid1: uid, uid2: partner)
                    if let dict = snapshot.value as? [String:AnyObject] {
                        if dict["blocked"] != nil {
                            mainStore.dispatch(ConversationRemoved(conversationKey: pairKey))
                        } else {
                            let seen = dict["seen"] as! Bool
                            let lastMessage = dict["text"] as! String
                            let timestamp = dict["latest"] as! Double
                            let date = Date(timeIntervalSince1970: timestamp/1000) as Date
                            let listening = true
                            
                            let conversation = Conversation(key: pairKey, partner_uid: partner, seen: seen, date: date, lastMessage: lastMessage, listening: listening)
                            mainStore.dispatch(ConversationChanged(conversation: conversation))
                        }
                        
                    }
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
            
            let notificationsRef = ref.child("users/notifications/\(current_uid)")
            notificationsRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    guard let seen = snapshot.value as? Bool else { return }
                    mainStore.dispatch(AddNotification(notificationKey: snapshot.key, seen: seen))
                }
            })
            
            notificationsRef.observe(.childChanged, with: { snapshot in
                if snapshot.exists() {
                    guard let seen = snapshot.value as? Bool else { return }
                    mainStore.dispatch(ChangeNotification(notificationKey: snapshot.key, seen: seen))
                }
            })
            
            notificationsRef.observe(.childRemoved, with: { snapshot in
                mainStore.dispatch(RemoveNotification(notificationKey: snapshot.key))
            })
            
        }
    }
    
    static func stopListeningToNotifications() {
        let uid = mainStore.state.userState.uid
        let notificationsRef = ref.child("notifications/\(uid)")
        notificationsRef.removeAllObservers()
        listeningToNotifications = false
    }
    
    static func startListeningToMyActivity() {
        if !listeningToMyActivity {
            listeningToMyActivity = true
            let current_uid = mainStore.state.userState.uid
            
            /*
            let myActivityRef = ref.child("users/story/\(current_uid)/posts")
            myActivityRef.observe(.value, with: { snapshot in
                var postKeys = [(String, Double)]()
                if snapshot.exists() {
                    if let _postsKeys = snapshot.value as? [String:Any]  {
                        //postKeys = _postsKeys.valueKeySorted
                        print("OBJECT: \(_postsKeys)")
                    }
                }
                mainStore.dispatch(SetMyActivity(posts: postKeys))
            })
            */
        }
    }
    
    
    
    static func startListeningToNearbyActivity() {
        if !listeningToNearbyActivity {
            listeningToNearbyActivity = true
            let current_uid = mainStore.state.userState.uid
            
            /*
            let nearbyActivityRef = ref.child("users/feed/nearby/\(current_uid)")
            nearbyActivityRef.observe(.value, with: { snapshot in
                var stories = [LocationStory]()
                if snapshot.exists() {
                    for place in snapshot.children {
                        let placeSnapshot = place as! FIRDataSnapshot
                        let placeId = placeSnapshot.key
                        if let object = placeSnapshot.value as? [String:AnyObject] {
                            if let distance = object["distance"] as? Double, let _postsKeys = object["posts"]  as? [String:Double] {
                                let postKeys:[(String,Double)] = _postsKeys.valueKeySorted
                                let story = LocationStory(postKeys: postKeys, locationKey: placeId, distance: distance)
                                stories.append(story)
                            }
                        }
                    }
                }
                print("New nearby place activity")
                mainStore.dispatch(SetNearbyPlacesActivity(stories: stories))
            })
            */
        }
    }
    
    static func stopListeningToMyActivity() {
        let uid = mainStore.state.userState.uid
        let myActivityRef = ref.child("users/story/\(uid)")
        myActivityRef.removeAllObservers()
        listeningToMyActivity = false
    }
    
    static func stopListeningToNearbyActivity() {
        let uid = mainStore.state.userState.uid
        let nearbyActivityRef = ref.child("notifications/\(uid)")
        nearbyActivityRef.removeAllObservers()
        listeningToNearbyActivity = false
    }
    
    static func startListeningToFollowingActivity() {
        if !listeningToFollowingActivity {
            listeningToFollowingActivity = true
            let current_uid = mainStore.state.userState.uid
            /*
            let followingActivityRef = ref.child("users/feed/following/\(current_uid)")
            followingActivityRef.observe(.value, with: { snapshot in
                var stories = [UserStory]()
                if snapshot.exists() {
                    
                    for user in snapshot.children {
                        let userSnapshot = user as! FIRDataSnapshot
                        let userId = userSnapshot.key
                        
                        if let _postsKeys = userSnapshot.value as? [String:Double] {
                            let postKeys:[(String,Double)] = _postsKeys.valueKeySorted
                            let story = UserStory(postKeys: postKeys, uid: userId)
                            stories.append(story)
                        }
                    }
                }
                print("New nearby place activity")
                mainStore.dispatch(SetFollowingActivity(stories: stories))
            })
            */
        }
    }
    
    static func stopListeningToFollowingActivity() {
        let uid = mainStore.state.userState.uid
        let followingActivityRef = ref.child("notifications/\(uid)")
        followingActivityRef.removeAllObservers()
        listeningToFollowingActivity = false
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
                        let childSnap = postKey as! FIRDataSnapshot
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
