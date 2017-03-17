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

                    user = User(uid: uid, username: username, imageURL: imageURL)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user)
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


    
    
    
}
