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
import Alamofire

var badges = [String:Badge]()
var availableBadgeKeys = [String]()

class UserService {
    
    
    fileprivate static let sm = SwiftMessages()
    static let ref = Database.database().reference()
    
    static var allowContent = false
    
    
    
    static func logout() {
        if let token = InstanceID.instanceID().token() {
            let fcmRef = ref.child("users/FCMToken/\(token)")
            fcmRef.removeValue() { error, ref in
                
                let uid = mainStore.state.userState.uid
                ref.child("users/badges/\(uid)").removeAllObservers()
                Listeners.stopListeningToAll()
                mainStore.dispatch(ClearSocialState())
                mainStore.dispatch(UserIsUnauthenticated())
                
                try! Auth.auth().signOut()
                
            }
        }
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
    
    static func getHTTPSHeaders(_ completion:@escaping (_ headers:HTTPHeaders?)->()) {
        Auth.auth().currentUser!.getIDToken() { token, error in
            
            if token == nil || error != nil {
                return completion(nil)
            }
            
            let headers: HTTPHeaders = ["Authorization": "Bearer \(token!)", "Accept": "application/json", "Content-Type" :"application/json"]
            return completion(headers)
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
    
    static func setAnonSetting(_ anonMode:Bool) {
        let uid = userState.uid
        let settingsRef = ref.child("users/settings/\(uid)/anonMode")
        settingsRef.setValue(anonMode) { error, ref in }
    }
    
    static func getAnonSetting() {
        let uid = userState.uid
        let settingsRef = ref.child("users/settings/\(uid)/anonMode")
        settingsRef.observeSingleEvent(of: .value, with: { snapshot in
            if let anonMode = snapshot.value as? Bool {
                if anonMode {
                    mainStore.dispatch(GoAnonymous())
                } else {
                    mainStore.dispatch(GoPublic())
                }
            }
        })
    }
    
    static func getAnonID() {
        let uid = mainStore.state.userState.uid
        let anonRef = ref.child("anon/aid/\(uid)")
        anonRef.observeSingleEvent(of: .value, with: { snapshot in
            if let anonID = snapshot.value as? String {
                mainStore.dispatch(SetAnonID(id: anonID))
            }
        })
    }
    
    static func getAllBadges() {
        let badgesRef = ref.child("badges")
        badgesRef.observeSingleEvent(of: .value, with: { snapshot in
            var _badges = [String:Badge]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                let key = childSnap.key
                let dict = childSnap.value as! [String:Any]
                
                let icon  = dict["icon"] as! String
                let title = dict["title"] as! String
                let desc  = dict["desc"] as! String
                
                let badge = Badge(key: key, icon: icon, title: title, desc: desc)
                badge.isAvailable = false
                _badges[key] = badge
            }
            
            badges = _badges
            self.observeUserBadges()
        })
        
    }
    
    static func observeUserBadges() {
        let uid = mainStore.state.userState.uid
        let badgesRef = ref.child("users/badges/\(uid)")
        badgesRef.observe(.value, with: { snapshot in
            var keys = [String:Bool]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                keys[childSnap.key] = true
                if let badge = badges[childSnap.key] {
                    badge.isAvailable = true
                }
            }
            
        })
        
    }

    static func getUserId(byUsername username: String, completion: @escaping ((_ uid:String?)->())) {
        ref.child("users/lookup/username").queryOrderedByValue().queryEqual(toValue: username).observeSingleEvent(of: .value, with: { snapshot in

            if let dict = snapshot.value as? [String:String], let first = dict.first {
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
                    
                    var verified = false
                    if let _ = dict["verified"] as? Bool {
                        verified = true
                    }
                    
                    
                    var badge:String = ""
                    if let _badge = dict["badge"] as? String {
                        badge = _badge
                    }
                    
                    user = User(uid: uid, username: username, firstname: firstname, lastname: lastname, imageURL: imageURL, bio: bio, posts: posts,followers: followers, following: following, verified: verified, badge: badge)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user)
            }, withCancel: { _ in
                completion(nil)
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
                
                var verified = false
                if let _ = dict["verified"] as? Bool {
                    verified = true
                }
                
                var badge:String = ""
                if let _badge = dict["badge"] as? String {
                    badge = _badge
                }
                
                user = User(uid: uid, username: username, firstname: firstname, lastname: lastname, imageURL: imageURL, bio: bio, posts: posts, followers: followers, following: following, verified: verified, badge: badge)
                dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
            }
            
            completion(user)
        }, withCancel: { _ in
            completion(nil)
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
                    
                    var verified = false
                    if let _ = dict["verified"] as? Bool {
                        verified = true
                    }
                    
                    var badge:String = ""
                    if let _badge = dict["badge"] as? String {
                        badge = _badge
                    }
                    
                    user = User(uid: uid, username: username, firstname: firstname, lastname: lastname, imageURL: imageURL, bio: bio, posts: posts, followers: followers, following: following, verified: verified, badge: badge)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user, check)
            }, withCancel: { _ in
                completion(nil, check)
            })
        }
    }
    
    static func getUserStory(_ uid:String, completion: @escaping ((_ story:UserStory?)->())) {
        
        let storyRef = ref.child("users/story/\(uid)/posts")
        
        storyRef.observeSingleEvent(of: .value, with: { snapshot in
            
            var story:UserStory?
            var postKeys = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                postKeys.append((childSnap.key, childSnap.value as! Double))
            }
            if postKeys.count > 0 {
                story = UserStory(postKeys: postKeys, uid: uid)
            }
            
            completion(story)
        
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    static func observeUserStory(_ uid:String, completion: @escaping ((_ story:UserStory?)->())) {
        
        let storyRef = ref.child("users/story/\(uid)/posts")
        
        storyRef.observe(.value, with: { snapshot in
            
            var story:UserStory?
            var postKeys = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                postKeys.append((childSnap.key, childSnap.value as! Double))
            }
            if postKeys.count > 0 {
                story = UserStory(postKeys: postKeys, uid: uid)
            }
            
            completion(story)
            
        }, withCancel: { error in
            completion(nil)
        })
    }
    
    static func stopObservingUserStory(_ uid:String) {
        let storyRef = ref.child("users/story/\(uid)/posts")
        storyRef.removeAllObservers()
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
        let reportRef = ref.child("reports/users/\(user.uid)/\(uid)")
        let value: [String: Any] = [
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
    
    static func reportAnonUser(aid:String, type:ReportType, completion:@escaping ((_ success:Bool)->())) {
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/anon_users/\(aid)/\(uid)")
        let value: [String: Any] = [
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
        
        
        let socialRef = ref.child("social/blockedUsers/\(current_uid)/\(uid)")
        socialRef.setValue([".sv": "timestamp"], withCompletionBlock: { error, ref in
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
        
        let socialRef = ref.child("social/blockedUsers/\(current_uid)/\(uid)")
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
    
    static func blockAnonUser(aid:String, completion:@escaping (_ success:Bool)->()) {
        let current_uid = mainStore.state.userState.uid
        
        
        let socialRef = ref.child("social/blockedAnonymous/\(current_uid)/\(aid)")
        socialRef.setValue([".sv": "timestamp"], withCompletionBlock: { error, ref in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "User blocked!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to block user.")
                return completion(false)
            }
        })
    }
    
    static func unblockAnonUser(aid:String, completion:@escaping (_ success:Bool)->()) {
        let current_uid = mainStore.state.userState.uid
        
        let socialRef = ref.child("social/blockedAnonymous/\(current_uid)/\(aid)")
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
