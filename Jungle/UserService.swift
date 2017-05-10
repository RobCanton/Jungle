//
//  UserService.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-16.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

//
//  UserService.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import SwiftMessages


class UserService {
    
    fileprivate static let sm = SwiftMessages()
    static let ref = FIRDatabase.database().reference()
    
    static var allowContent = false
    
    static func logout() {
        Listeners.stopListeningToAll()
        mainStore.dispatch(ClearAllNotifications())
        mainStore.dispatch(ClearConversations())
        mainStore.dispatch(ClearMyActivity())
        mainStore.dispatch(ClearSocialState())
        mainStore.dispatch(UserIsUnauthenticated())
        
        try! FIRAuth.auth()!.signOut()
        globalMainRef?.dismiss(animated: false, completion: nil)
    }

//    
    static func sendFCMToken() {
        if let token = FIRInstanceID.instanceID().token() {
            if let user = mainStore.state.userState.user {
                let fcmRef = ref.child("users/FCMToken/\(user.getUserId())")
                fcmRef.setValue(token)
            }
        }
    }
//
    
    static func getUserId(byUsername username: String, completion: @escaping ((_ uid:String?)->())) {
        ref.child("users/lookup/username/uid/\(username)").observeSingleEvent(of: .value, with: { snapshot in
            let uid = snapshot.value as? String
            completion(uid)
        })
    }

    static func getUser(_ uid:String, completion: @escaping (_ user:User?) -> Void) {
        if let cachedUser = dataCache.object(forKey: "user-\(uid)" as NSString as NSString) as? User {
            completion(cachedUser)
        } else {
            ref.child("users/profile/\(uid)").observe(.value, with: { snapshot in
                var user:User?
                if snapshot.exists() {
                    let dict = snapshot.value as! [String:AnyObject]
                    guard let username = dict["username"] as? String else { return completion(user) }
                    guard let imageURL = dict["imageURL"] as? String else { return completion(user) }
                    guard let bio      = dict["bio"] as? String else { return completion(user) }
                    
                    user = User(uid: uid, username: username, imageURL: imageURL, bio: bio)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user)
            })
        }
    }
    
    static func getUser(withCheck check: Int, uid:String, completion: @escaping ((_ check:Int, _ user:User?)->())) {
        getUser(uid, completion: { user in
            completion(check, user)
        })
    }
    
    
    
    static func getUser(_ uid:String,withCheck check:Int, completion: @escaping (_ user:User?,_ check:Int) -> Void) {
        if let cachedUser = dataCache.object(forKey: "user-\(uid)" as NSString as NSString) as? User {
            completion(cachedUser, check)
        } else {
            ref.child("users/profile/\(uid)").observe(.value, with: { snapshot in
                var user:User?
                if snapshot.exists() {
                    let dict = snapshot.value as! [String:AnyObject]
                    guard let username = dict["username"] as? String else { return completion(user, check) }
                    guard let imageURL = dict["imageURL"] as? String else { return completion(user, check) }
                    guard let bio      = dict["bio"] as? String else { return completion(user, check) }
                    
                    user = User(uid: uid, username: username, imageURL: imageURL, bio: bio)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user, check)
            })
        }
    }
    
    static func getUserStory(_ uid:String, completion: @escaping ((_ story:UserStory?)->())) {
        let storyRef = ref.child("stories/users/\(uid)")
        storyRef.observe(.value, with: { snapshot in
            var story:UserStory?
            if let dict = snapshot.value as? [String:AnyObject] {
                if let meta = dict["meta"] as? [String:AnyObject], let postObject = dict["posts"] as? [String:AnyObject] {
                    let lastPost = meta["k"] as! String
                    let timestamp = meta["t"] as! Double
                    var popularity = 0
                    if let p = meta["p"] as? Int {
                        popularity = p
                    }
                    var posts = [String]()
                    for (key,_) in postObject {
                        posts.append(key)
                    }
                    story = UserStory(posts: posts, lastPostKey: lastPost, timestamp: timestamp, popularity:popularity, uid: snapshot.key)
                }
            }
            completion(story)

        })
    }
    
    static func getPlaceStory(_ placeId:String, completion: @escaping ((_ story:LocationStory?)->())) {
        let storyRef = ref.child("stories/places/\(placeId)")
        storyRef.observe(.value, with: { snapshot in
            var story:LocationStory?
            if let dict = snapshot.value as? [String:AnyObject] {
                if let meta = dict["meta"] as? [String:AnyObject], let postObject = dict["posts"] as? [String:AnyObject] {
                    let lastPost = meta["k"] as! String
                    let timestamp = meta["t"] as! Double
                    var popularity = 0
                    if let p = meta["p"] as? Int {
                        popularity = p
                    }
                    var posts = [String]()
                    for (key,_) in postObject {
                        posts.append(key)
                    }
                    story = LocationStory(posts: posts, lastPostKey: lastPost, timestamp: timestamp, popularity: popularity, locationKey: snapshot.key, distance: 0)
                    //story = UserStory(posts: posts, lastPostKey: lastPost, timestamp: timestamp, popularity:popularity, uid: snapshot.key)
                }
            }
            completion(story)
            
        })
    }
//
    

    
//
//    static func uploadProfilePicture(largeImage:UIImage, smallImage:UIImage , completionHandler:@escaping (_ success:Bool, _ largeImageURL:String?, _ smallImageURL:String?)->()) {
//        let storageRef = FIRStorage.storage().reference()
//        if let largeImageTask = uploadLargeProfilePicture(image: largeImage) {
//            largeImageTask.observe(.success, handler: { largeImageSnapshot in
//                if let smallImageTask = uploadSmallProfilePicture(image: smallImage) {
//                    smallImageTask.observe(.success, handler: { smallImageSnapshot in
//                        let largeImageURL = largeImageSnapshot.metadata!.downloadURL()!.absoluteString
//                        let smallImageURL =  smallImageSnapshot.metadata!.downloadURL()!.absoluteString
//                        completionHandler(true,largeImageURL, smallImageURL)
//                    })
//                    smallImageTask.observe(.failure, handler: { _ in completionHandler(false , nil, nil) })
//                } else { completionHandler(false , nil, nil) }
//            })
//            largeImageTask.observe(.failure, handler: { _ in completionHandler(false , nil, nil) })
//        } else { completionHandler(false , nil, nil)}
//        
//    }
    

    static func uploadProfileImage(image:UIImage, completion: @escaping ((_ downloadURL:String?) ->())) {
        guard let user = FIRAuth.auth()?.currentUser else {
            completion(nil)
            return
        }
        
        
        
        let storageRef = FIRStorage.storage().reference()
        let imageRef = storageRef.child("user_profiles/\(user.uid)")
        if let picData = UIImageJPEGRepresentation(image, 0.9) {
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            imageRef.put(picData, metadata: metadata) { metadata, error in
                if error == nil && metadata != nil {
                    let url =  metadata!.downloadURL()!.absoluteString
                    completion(url)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func followUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let socialRef = ref.child("users/social")
        let userRef = socialRef.child("followers/\(uid)/\(current_uid)")
        userRef.setValue(false)
        
        
        let currentUserRef = socialRef.child("following/\(current_uid)/\(uid)")
        currentUserRef.setValue(false, withCompletionBlock: {
            error, ref in
        })
        
        //unblockUser(uid: uid, completionHandler: { success in })
        
        
    }
    
    static func unfollowUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let userRef = ref.child("users/social/followers/\(uid)/\(current_uid)")
        userRef.removeValue()
        
        let currentUserRef = ref.child("users/social/following/\(current_uid)/\(uid)")
        currentUserRef.removeValue()
        
    }
    
    static func sendMessage(conversation:Conversation, message:String, uploadKey:String?, completion: ((_ success:Bool)->())?) {
        let convoRef = ref.child("conversations/\(conversation.getKey())")
        
        let messageRef = convoRef.child("messages").childByAutoId()
        let uid = mainStore.state.userState.uid
        
        let updateObject = [
                "senderId": uid as AnyObject,
                "text": message as AnyObject,
                "timestamp": [".sv":"timestamp"] as AnyObject
        ] as [String:AnyObject]
        
        messageRef.setValue(updateObject, withCompletionBlock: { error, ref in })
    }

    static func listenToFollowers(uid:String, completion:@escaping (_ followers:[String])->()) {
        let followersRef = ref.child("users/social/followers/\(uid)")
        followersRef.observe(.value, with: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                let dict = snapshot.value as! [String:Bool]
                
                for (uid, _) in dict {
                    _users.append(uid)
                }
            }
            completion(_users)
        })
    }
    
    static func listenToFollowing(uid:String, completion:@escaping (_ following:[String])->()) {
        let followingRef = ref.child("users/social/following/\(uid)")
        followingRef.observe(.value, with: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                let dict = snapshot.value as! [String:Bool]
                
                for (uid, _) in dict {
                    _users.append(uid)
                }
            }
            completion(_users)
        })
    }
    
    static func stopListeningToFollowers(uid:String) {
        if uid != mainStore.state.userState.uid {
            ref.child("users/social/followers/\(uid)").removeAllObservers()
        }
    }
    
    static func stopListeningToFollowing(uid:String) {
        if uid != mainStore.state.userState.uid {
            ref.child("users/social/following/\(uid)").removeAllObservers()
        }
    }
    
    static func reportUser(user:User, type:ReportType, completion:@escaping ((_ success:Bool)->())) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/\(uid):\(user.getUserId())")
        let value: [String: Any] = [
            "sender": uid,
            "userId": user.getUserId(),
            "type": type.rawValue,
            "timestamp": [".sv": "timestamp"]
        ]
        reportRef.setValue(value, withCompletionBlock: { error, ref in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Report sent!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to send report.")
                return completion(false)
            }
        })
    }
    
    static func blockUser(uid:String, completion:@escaping (_ success:Bool)->()) {
        let current_uid = mainStore.state.userState.uid
        
        let socialRef = ref.child("users/social")
        let updateData = [
            "blocked/\(current_uid)/\(uid)":true,
            "blocked_by/\(uid)/\(current_uid)":true
        ]
        socialRef.updateChildValues(updateData, withCompletionBlock: { error, ref in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "User blocked!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to block user.")
                return completion(false)
            }
        })
    }
    
}
