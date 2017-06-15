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
    static let ref = Database.database().reference()
    
    static var allowContent = false
    
    static func logout() {
        Listeners.stopListeningToAll()
        mainStore.dispatch(ClearSocialState())
        mainStore.dispatch(UserIsUnauthenticated())
        
        try! Auth.auth().signOut()
    }
    
    static var isEmailVerified:Bool {
        get {
            if let user = Auth.auth().currentUser {
                return user.isEmailVerified
            } else {
                return false
            }
        }
    }
    
    static var email:String? {
        get {
            return Auth.auth().currentUser?.email
        }
    }
    
    static func sendVerificationEmail(completion:@escaping ((_ success:Bool)->())) {
        Auth.auth().currentUser?.sendEmailVerification { error in
            completion(error == nil )
        }
    }

    static func sendFCMToken() {
        if let token = InstanceID.instanceID().token() {
            if let user = mainStore.state.userState.user {
                let fcmRef = ref.child("users/FCMToken/\(token)")
                fcmRef.setValue(user.uid)
            }
        }
    }
    
    

    static func getUserId(byUsername username: String, completion: @escaping ((_ uid:String?)->())) {
        ref.child("users/lookup/username").queryOrderedByValue().queryEqual(toValue: username).observeSingleEvent(of: .value, with: { snapshot in

            if let dict = snapshot.value as? [String:String], let first = dict.first {
                print("DICT: \(dict)")
                completion(first.key)
            } else {
                completion(nil)
            }
            
        })
    }
    
    static func checkUsernameAvailability(byUsername username: String, completion: @escaping ((_ username:String, _ available:Bool)->())) {
        ref.child("users/lookup/username").queryOrderedByValue().queryEqual(toValue: username).observeSingleEvent(of: .value, with: { snapshot in
            completion(username, !snapshot.exists())
        })
    }

    static func getUser(_ uid:String, completion: @escaping (_ user:User?) -> Void) {
        if let cachedUser = dataCache.object(forKey: "user-\(uid)" as NSString as NSString) as? User {
            completion(cachedUser)
        } else {
            ref.child("users/profile/\(uid)").observeSingleEvent(of: .value, with: { snapshot in
                var user:User?
                if snapshot.exists() {
                    let dict = snapshot.value as! [String:AnyObject]
                    guard let username = dict["username"] as? String else { return completion(user) }
                    guard let imageURL = dict["imageURL"] as? String else { return completion(user) }
                    guard let bio      = dict["bio"] as? String else { return completion(user) }
                    guard let firstname = dict["firstname"] as? String else { return completion(user) }
                    var lastname:String = ""
                    if let _lastname = dict["lastname"] as? String {
                        lastname = _lastname
                    }
                    
                    var posts:Int = 0
                    if let _posts = dict["posts"] as? Int {
                        posts = _posts
                    }
                    
                    var followers:Int = 0
                    if let _followers = dict["followers"] as? Int {
                        followers = _followers
                    }
                    
                    var following:Int = 0
                    if let _following = dict["following"] as? Int {
                        following = _following
                    }
                    
                    user = User(uid: uid, username: username, firstname: firstname, lastname: lastname, imageURL: imageURL, bio: bio, posts: posts,followers: followers, following: following)
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
    
    
    
    static func observeUser(_ uid:String, completion: @escaping (_ user:User?) -> Void) {
        ref.child("users/profile/\(uid)").observe(.value, with: { snapshot in
            var user:User?
            print("PROFILE CHANGED TINGS!")
            if snapshot.exists() {
                let dict = snapshot.value as! [String:AnyObject]
                guard let username = dict["username"] as? String else { return completion(user) }
                guard let imageURL = dict["imageURL"] as? String else { return completion(user) }
                guard let bio      = dict["bio"] as? String else { return completion(user) }
                guard let firstname = dict["firstname"] as? String else { return completion(user) }
                var lastname:String = ""
                if let _lastname = dict["lastname"] as? String {
                    lastname = _lastname
                }
                
                var posts:Int = 0
                if let _posts = dict["posts"] as? Int {
                    posts = _posts
                }
                
                var followers:Int = 0
                if let _followers = dict["followers"] as? Int {
                    followers = _followers
                }
                
                var following:Int = 0
                if let _following = dict["following"] as? Int {
                    following = _following
                }
                
                user = User(uid: uid, username: username, firstname: firstname, lastname: lastname, imageURL: imageURL, bio: bio, posts: posts, followers: followers, following: following)
                dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
            }
            
            completion(user)
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
                    guard let firstname = dict["firstname"] as? String else { return completion(user, check) }
                    
                    var lastname:String = ""
                    if let _lastname = dict["lastname"] as? String {
                        lastname = _lastname
                    }
                    
                    var posts:Int = 0
                    if let _posts = dict["posts"] as? Int {
                        posts = _posts
                    }
                    
                    var followers:Int = 0
                    if let _followers = dict["followers"] as? Int {
                        followers = _followers
                    }
                    
                    var following:Int = 0
                    if let _following = dict["following"] as? Int {
                        following = _following
                    }
                    
                    user = User(uid: uid, username: username, firstname: firstname, lastname: lastname, imageURL: imageURL, bio: bio, posts: posts, followers: followers, following: following)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user, check)
            })
        }
    }
    
    static func getUserStory(_ uid:String, completion: @escaping ((_ story:UserStory?)->())) {
        
        let storyRef = ref.child("users/story/\(uid)")
        
        storyRef.observeSingleEvent(of: .value, with: { snapshot in
            var story:UserStory?
            if let dict = snapshot.value as? [String:AnyObject], let _postsKeys = dict["posts"]  as? [String:Double] {
                let postKeys:[(String,Double)] = _postsKeys.valueKeySorted
                story = UserStory(postKeys: postKeys, uid: uid)

            }
            completion(story)
        
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    
    static func getPlaceStory(_ placeId:String, completion: @escaping ((_ story:LocationStory?)->())) {
        completion(nil)
//        let storyRef = ref.child("stories/places/\(placeId)")
//        storyRef.observe(.value, with: { snapshot in
//            var story:LocationStory?
//            if let dict = snapshot.value as? [String:AnyObject] {
//                if let meta = dict["meta"] as? [String:AnyObject], let postObject = dict["posts"] as? [String:AnyObject] {
//                    let lastPost = meta["k"] as! String
//                    let timestamp = meta["t"] as! Double
//                    var popularity = 0
//                    if let p = meta["p"] as? Int {
//                        popularity = p
//                    }
//                    var posts = [String]()
//                    for (key,_) in postObject {
//                        posts.append(key)
//                    }
//                    story = LocationStory(posts: posts, lastPostKey: lastPost, timestamp: timestamp, popularity: popularity, locationKey: snapshot.key)
//                }
//            }
//            completion(story)
//            
//        })
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
        guard let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("user_profiles/\(user.uid)")
        if let picData = UIImageJPEGRepresentation(image, 0.9) {
            let contentTypeStr = "image/jpg"
            let metadata = StorageMetadata()
            metadata.contentType = contentTypeStr
            imageRef.putData(picData, metadata: metadata) { metadata, error in
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
        
        let socialRef = ref.child("social/following/\(current_uid)/\(uid)")
        
        socialRef.setValue(false, withCompletionBlock: {
            error, ref in
        })
        
        //unblockUser(uid: uid, completionHandler: { success in })
        
        
    }
    
    static func unfollowUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let currentUserRef = ref.child("social/following/\(current_uid)/\(uid)")
        currentUserRef.removeValue()
        
    }

    static func sendMessage(conversationKey:String,recipientId:String, message:String, completion: ((_ success:Bool)->())?) {
        let convoRef = Database.database().reference().child("conversations/\(conversationKey)")
        let messageRef = convoRef.child("messages").childByAutoId()
        let uid = mainStore.state.userState.uid
        
        let updateObject = [
            "recipientId": recipientId,
            "senderId": uid as AnyObject,
            "text": message as AnyObject,
            "timestamp": [".sv":"timestamp"] as AnyObject
            ] as [String:AnyObject]
        
        messageRef.setValue(updateObject, withCompletionBlock: { error, ref in
            completion?(error == nil)
        })
    }
    
    static func listenToFollowers(uid:String, completion:@escaping (_ followers:[String])->()) {
        let followersRef = ref.child("social/followers/\(uid)")
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
        let followingRef = ref.child("social/following/\(uid)")
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
            ref.child("social/followers/\(uid)").removeAllObservers()
        }
    }
    
    static func stopListeningToFollowing(uid:String) {
        if uid != mainStore.state.userState.uid {
            ref.child("social/following/\(uid)").removeAllObservers()
        }
    }
    
    static func reportUser(user:User, type:ReportType, completion:@escaping ((_ success:Bool)->())) {
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/\(uid):\(user.uid)")
        let value: [String: Any] = [
            "sender": uid,
            "userId": user.uid,
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
        
        let socialRef = ref.child("social/blocked/\(current_uid)/\(uid)")
        socialRef.setValue(true, withCompletionBlock: { error, ref in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "User blocked!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to block user.")
                return completion(false)
            }
        })
    }
    
    static func unblockUser(uid:String, completion:@escaping (_ success:Bool)->()) {
        let current_uid = mainStore.state.userState.uid
        
        let socialRef = ref.child("social/blocked/\(current_uid)/\(uid)")
        socialRef.removeValue(completionBlock: { error, ref in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "User unblocked!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to unblock user.")
                return completion(false)
            }
        })
        
    }
    
}
