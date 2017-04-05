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



class UserService {
    
    static let ref = FIRDatabase.database().reference()
    
    static var allowContent = false

//    
//    static func sendFCMToken() {
//        if let token = FIRInstanceID.instanceID().token() {
//            if let user = mainStore.state.userState.user {
//                let fcmRef = ref.child("users/FCMToken/\(user.getUserId())")
//                fcmRef.setValue(token)
//            }
//        }
//    }
//    

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
        
        let followRequestRef = ref.child("api/requests/social").childByAutoId()
        followRequestRef.setValue([
            "type": "FOLLOW",
            "sender": current_uid,
            "recipient": uid,
            "timestamp": [".sv":"timestamp"] as AnyObject
            ])
        
        
        //unblockUser(uid: uid, completionHandler: { success in })
        
        
    }
    
    static func unfollowUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let userRef = ref.child("users/social/followers/\(uid)/\(current_uid)")
        userRef.removeValue()
        
        let currentUserRef = ref.child("users/social/following/\(current_uid)/\(uid)")
        currentUserRef.removeValue()
        
//        let followRequestRef = ref.child("api/requests/social").childByAutoId()
//        followRequestRef.setValue([
//            "type": "UNFOLLOW",
//            "sender": current_uid,
//            "recipient": uid
//            ])
    }
    
    static func sendMessage(conversation:Conversation, message:String, uploadKey:String?, completion: ((_ success:Bool)->())?) {
        let messageRef = ref.child("conversations/\(conversation.getKey())/messages").childByAutoId()
        let uid = mainStore.state.userState.uid
        
        let requestRef = ref.child("api/requests/message").childByAutoId()
        requestRef.setValue([
            "conversation": conversation.getKey(),
            "sender": uid as AnyObject,
            "recipient": conversation.getPartnerId() as AnyObject,
            "text": message as AnyObject,
            "timestamp": [".sv":"timestamp"] as AnyObject
            ])
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
    
}
