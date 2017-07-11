//
//  UploadService.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation
import AVFoundation
import GooglePlaces
import GoogleMaps
import SwiftMessages
import Alamofire


let dataCache = NSCache<NSString, AnyObject>()
let uploadDataCache = NSCache<NSString, AnyObject>()
class UploadService {
    
    static var lastCommentTime:Date?
    fileprivate static let sm = SwiftMessages()
    
    static func writeImageToFile(withKey key:String, image:UIImage) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("user_content/upload_image-\(key).jpg")
        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
            do {
                try jpgData.write(to: dataPath, options: [.atomic])
            } catch {
                print("Error writing to disk")
            }
        }
    }
    
    static func readImageFromFile(withKey key:String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("user_content/upload_image-\(key).jpg")
        return UIImage(contentsOfFile: dataPath.path)
    }
    
    static func imageFileExists(withKey key:String) -> Bool {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("user_content/upload_image-\(key).jpg")
        let exists = FileManager.default.fileExists(atPath: dataPath.path)
        return exists
    }
    
    static func videoFileExists(withKey key:String) -> Bool {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("user_content/upload_video-\(key).mp4")
        let exists = FileManager.default.fileExists(atPath: dataPath.path)
        return exists
    }
    
    fileprivate static func downloadImage(withUrl url:URL, completion: @escaping (_ image:UIImage?)->()) {
        
        URLSession.shared.dataTask(with: url, completionHandler:
            { (data, response, error) in
                if error != nil {
                    if error?._code == -999 {
                        return
                    }
                    return completion(nil)
                }
                
                DispatchQueue.main.async {
                    var image:UIImage?
                    if data != nil {
                        image = UIImage(data: data!)
                    }
                    return completion(image)
                }
                
        }).resume()
    }
    
    static func retrieveImage(byKey key: String, withUrl url:URL, completion: @escaping (_ image:UIImage?, _ fromFile:Bool)->()) {
        if let image = readImageFromFile(withKey: key) {
            completion(image, true)
        } else {
            downloadImage(withUrl: url) { image in
                if image != nil {
                    writeImageToFile(withKey: key, image: image!)
                }
                completion(image, false)
            }
        }
    }
    
    static func retrieveImage(withCheck check:Int, key:String, url:URL, completion: @escaping (_ check:Int, _ image:UIImage?, _ fromFile:Bool)->()) {
        retrieveImage(byKey: key, withUrl: url) { image, fromFile in
            completion(check, image, fromFile)
        }
    }
    
    static func retrieveImageWithReturnKey(byKey key: String, withUrl url:URL, completion: @escaping (_ image:UIImage?, _ fromFile:Bool, _ key:String)->()) {
        if let image = readImageFromFile(withKey: key) {
            completion(image, true, key)
        } else {
            downloadImage(withUrl: url, completion: { image in
                if image != nil {
                    writeImageToFile(withKey: key, image: image!)
                }
                completion(image, false, key)
            })
        }
    }
    
    static func writeVideoToFile(withKey key:String, video:Data) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("user_content/upload_video-\(key).mp4")

        try! video.write(to: dataPath, options: [.atomic])
        return dataPath
    }
    
    static func readVideoFromFile(withKey key:String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent("user_content/upload_video-\(key).mp4")
        do {
            let _ = try Data(contentsOf: dataPath)
            
            return dataPath
        } catch let error as Error{
            //print("ERROR: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    fileprivate static func downloadVideo(byAuthor author:String, withKey key:String, completion: @escaping (_ data:Data?)->()) {
        let videoRef = Storage.storage().reference().child("user_uploads/\(author)/\(key).mp4")
        
        // Download in memory with a maximum allowed size of 2MB (2 * 1024 * 1024 bytes)
        videoRef.getData(maxSize: 2 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                print("Error - \(error!.localizedDescription)")
                completion(nil)
            } else {
                return completion(data!)
            }
        }
    }
    
    static func retrieveVideo(byAuthor author:String, withKey key:String, completion: @escaping (_ videoUrl:URL?, _ fromFile:Bool)->()) {
        if let data = readVideoFromFile(withKey: key) {
            completion(data, true)
        } else {
            downloadVideo(byAuthor: author, withKey: key, completion: { data in
                if data != nil {
                    let url = writeVideoToFile(withKey: key, video: data!)
                    completion(url, false)
                }
                completion(nil, false)
            })
        }
    }
    
    static func retrievePostImageVideo(post:StoryItem, completion: @escaping ((_ post:StoryItem)->())) {
        retrieveImage(byKey: post.key, withUrl: post.downloadUrl, completion: { image, fromFile in
            if post.contentType == .image {
                completion(post)
            } else if post.contentType == .video {
                if let _ = readVideoFromFile(withKey: post.key) {
                    completion(post)
                } else {
                    retrieveVideo(byAuthor: post.authorId, withKey: post.key, completion: { data in
                        completion(post)
                    })
                }
            }
        })
    }

    static func sendImage(upload:Upload, completion: (()->())) {
        
        //If upload has no destination do not upload it
        guard let image = upload.image else { return }
        
        let ref = Database.database().reference()
        let dataRef = ref.child("uploads/meta").childByAutoId()
        let postKey = dataRef.key
        
        let uid = mainStore.state.userState.uid
        
        Alerts.showStatusProgressAlert(inWrapper: sm, withMessage: "Uploading...")
        
        let avgColor = image.areaAverage()
        let saturatedColor = avgColor.modified(withAdditionalHue: 0, additionalSaturation: 0.3, additionalBrightness: 0.20)
        let colorHex = saturatedColor.htmlRGBColor
        if let data = UIImageJPEGRepresentation(image, 0.5) {
            // Create a reference to the file you want to upload
            // Create the file metadata
            let contentTypeStr = "image"
            let metadata = StorageMetadata()
            metadata.contentType = contentTypeStr
            
            // Upload file and metadata to the object
            let storageRef = Storage.storage().reference()
            let uploadTask = storageRef.child("user_uploads/\(uid)/\(postKey).jpg").putData(data, metadata: metadata) { metadata, error in
                
                if (error != nil) {
                    return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to upload.")
                } else {
                    
                    
                    Auth.auth().currentUser!.getIDToken() { token, error in
                        
                        if error != nil { return }
                        
                        guard let tokenID = token else { return }
                        
                        // Metadata contains file metadata such as size, content-type, and download URL.
                        let downloadURL = metadata!.downloadURL()
                        var obj = [
                            "url": downloadURL!.absoluteString,
                            "contentType": contentTypeStr,
                            "length": 6.0,
                            "color": colorHex,
                            ] as [String : Any]
                        
                        if let coordinates = upload.coordinates {
                            obj["coordinates"] = [
                                "lat": coordinates.coordinate.latitude,
                                "lon":coordinates.coordinate.longitude
                            ] as [String: Any]
                        }
                        
                        if let place = upload.place {
                            obj["placeID"] = place.placeID
                        }
                        
                        if let caption = upload.caption {
                            obj["caption"] = caption
                        }
                        
                        if let aid = userState.anonID, userState.anonMode {
                            obj["aid"] = aid
                        }
                        
                        
                        let headers: HTTPHeaders = ["Authorization": "Bearer \(tokenID)", "Accept": "application/json", "Content-Type" :"application/json"]
                        print("ALAMOFIRE REQEUST")
                        Alamofire.request("https://us-central1-jungleiosapp.cloudfunctions.net/app/upload", method: .post, parameters: obj, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            DispatchQueue.main.async {
                                
                                // result of response serialization : SUCCESS / FAILURE
                                print("Response result is :",response.result)
                                
                                switch response.result {
                                case .success:
                                    print("Validation Successful")
                                    return Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Uploaded!")
                                case .failure(let error):
                                    print(error)
                                    return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to upload.")
                                }
                            
                            }
                            
                        }
                        
                        
                    }
                    
                    
//                    let requestRef = ref.child("api/requests/\(uid)/upload/add").childByAutoId()
//                    
//                    requestRef.setValue(obj) { error, ref in
//                        print("uploaded!")
//                    }
                    /*
                    if let anonObject = upload.anonObject {
                        anonMode = true
                        obj["author"] = userState.anonID!
                        obj["anon"] = [
                            "adjective": anonObject.adjective,
                            "animal": anonObject.animal,
                            "color": anonObject.colorHexcode
                            ] as [String : Any]
                    }
                    
                    if let place = upload.place {
                        obj["placeID"] = place.placeID
                    }
                    
                    if let caption = upload.caption {
                        obj["caption"] = caption
                    }
                    
                    var updateValues: [String : Any] = [
                        "uploads/meta/\(postKey)": obj,
                        "users/uploads/\(uid)/\(postKey)": [".sv": "timestamp"],
                        "users/story/\(uid)/posts/\(postKey)": [".sv": "timestamp"]
                    ]
                    
                    if !anonMode {
                        updateValues["users/uploads/\(uid)/\(postKey)"] = [".sv": "timestamp"]
                        updateValues["users/story/\(uid)/posts/\(postKey)"] = [".sv": "timestamp"]
                    } else {
                        
                    }
                    
                    
                    
                    if let coordinates = upload.coordinates {
                        updateValues["uploads/location/\(postKey)/u"] = uid
                        updateValues["uploads/location/\(postKey)/lat"] = coordinates.coordinate.latitude
                        updateValues["uploads/location/\(postKey)/lon"] = coordinates.coordinate.longitude
                        updateValues["uploads/location/\(postKey)/t"]   = [".sv": "timestamp"]
                        if let place = upload.place {
                            let placeId = place.placeID
                            updateValues["places/info/\(placeId)/name"] = place.name
                            updateValues["places/info/\(placeId)/lat"] = place.coordinate.latitude
                            updateValues["places/info/\(placeId)/lon"] = place.coordinate.longitude
                            updateValues["places/info/\(placeId)/address"] = place.formattedAddress
                            for type in place.types {
                                updateValues["places/info/\(place.placeID)/types/\(type)"] = true
                            }
                            updateValues["places/coords/\(placeId)/lat"] = place.coordinate.latitude
                            updateValues["places/coords/\(placeId)/lon"] = place.coordinate.longitude
                            updateValues["places/posts/\(placeId)/\(postKey)"] = [".sv": "timestamp"]
                            updateValues["places/story/\(placeId)/\(postKey)/t"] = [".sv": "timestamp"]
                            updateValues["places/story/\(placeId)/\(postKey)/u"] = uid
                        }
                    }
                    
                    print(updateValues)
                    
                    ref.updateChildValues(updateValues, withCompletionBlock: { error, ref in
                        if error == nil {
                            globalMainInterfaceProtocol?.fetchAllStories()
                            
                            let subscriberRef = ref.child("uploads/subscribers/\(postKey)/\(uid)")
                            subscriberRef.setValue(true)
                            
                            return Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Uploaded!")
                        } else {
                            return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to upload.")
                        }
                    })
                    */
                }
            }
            completion()
        }
    }
    
    static func uploadVideo(upload:Upload, completion:(_ success:Bool)->()){
        
        if upload.videoURL == nil { return }
        
        let url = upload.videoURL!
        
        let ref = Database.database().reference()
        let dataRef = ref.child("uploads/meta").childByAutoId()
        let postKey = dataRef.key
        
        Alerts.showStatusProgressAlert(inWrapper: sm, withMessage: "Uploading...")
        
        let storageRef = Storage.storage().reference()
        if let videoStill = generateVideoStill(url: url) {
            let avgColor = videoStill.areaAverage()
            let saturatedColor = avgColor.modified(withAdditionalHue: 0, additionalSaturation: 0.3, additionalBrightness: 0.20)
            let colorHex = saturatedColor.htmlRGBColor
            if let data = UIImageJPEGRepresentation(videoStill, 0.5) {
                
                completion(true)
                
                let stillMetaData = StorageMetadata()
                stillMetaData.contentType = "image"
                let uid = mainStore.state.userState.uid
                storageRef.child("user_uploads/\(uid)/\(postKey).jpg").putData(data, metadata: stillMetaData) { metadata, error in
                  
                    let thumbURL = metadata?.downloadURL()?.absoluteString
                    if (thumbURL == nil || error != nil) {
                        return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to upload.")
                    }
                    
                    let data = NSData(contentsOf: url)
                    
                    let metadata = StorageMetadata()
                    let contentTypeStr = "video"
                    let playerItem = AVAsset(url: url)
                    let length = CMTimeGetSeconds(playerItem.duration)
                    metadata.contentType = contentTypeStr
                    
                    let storageRef = Storage.storage().reference()
                    storageRef.child("user_uploads/\(uid)/\(postKey).mp4").putData(data as! Data, metadata: metadata) { metadata, error in
                        
                        if (error != nil) {
                            // HANDLE ERROR
                            return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to upload.")
                        } else {
                            // Metadata contains file metadata such as size, content-type, and download URL.
                            
                            let downloadURL = metadata!.downloadURL()
                            var obj = [
                                "author": uid,
                                "url": thumbURL!,
                                "videoURL": downloadURL!.absoluteString,
                                "contentType": contentTypeStr,
                                "dateCreated": [".sv": "timestamp"],
                                "length": length,
                                "color": colorHex,
                                "live":true,
                                ] as [String : Any]
                            
                            if let place = upload.place {
                                obj["placeID"] = place.placeID
                            }
                            
                            if let caption = upload.caption {
                                obj["caption"] = caption
                            }
                            
                            var updateValues: [String : Any] = [
                                "uploads/meta/\(postKey)": obj,
                                "users/uploads/\(uid)/\(postKey)": [".sv": "timestamp"],
                                "users/story/\(uid)/posts/\(postKey)": [".sv": "timestamp"]
                            ]
                            
                            if let coordinates = upload.coordinates {
                                updateValues["uploads/location/\(postKey)/u"] = uid
                                updateValues["uploads/location/\(postKey)/lat"] = coordinates.coordinate.latitude
                                updateValues["uploads/location/\(postKey)/lon"] = coordinates.coordinate.longitude
                                updateValues["uploads/location/\(postKey)/t"]   = [".sv": "timestamp"]
                                
                                if let place = upload.place {
                                    let placeId = place.placeID
                                    updateValues["places/info/\(placeId)/name"] = place.name
                                    updateValues["places/info/\(placeId)/lat"] = place.coordinate.latitude
                                    updateValues["places/info/\(placeId)/lon"] = place.coordinate.longitude
                                    updateValues["places/info/\(placeId)/address"] = place.formattedAddress
                                    for type in place.types {
                                        updateValues["places/info/\(place.placeID)/types/\(type)"] = true
                                    }
                                    updateValues["places/coords/\(placeId)/lat"] = place.coordinate.latitude
                                    updateValues["places/coords/\(placeId)/lon"] = place.coordinate.longitude
                                    updateValues["places/posts/\(placeId)/\(postKey)"] = [".sv": "timestamp"]
                                    updateValues["places/story/\(placeId)/\(postKey)/t"] = [".sv": "timestamp"]
                                    updateValues["places/story/\(placeId)/\(postKey)/u"] = uid
                                }
                            }
                            
                            ref.updateChildValues(updateValues, withCompletionBlock: { error, ref in
                                
                                if error == nil {
                                    globalMainInterfaceProtocol?.fetchAllStories()
                                    
                                    let subscriberRef = ref.child("uploads/subscribers/\(postKey)/\(uid)")
                                    subscriberRef.setValue(true)
                                    
                                    return Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Uploaded!")
                                } else {
                                    return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to upload.")
                                }
                            })
                        }
                    }
                    
                    
                }
            }
        } else {
            completion(false)
        }

    }
    
    private static func generateVideoStill(url:URL) -> UIImage?{
        do {
            let asset = AVAsset(url: url)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            return image
        } catch let error as NSError {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    static func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ session: AVAssetExportSession)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        if let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileTypeMPEG4
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.exportAsynchronously { () -> Void in
                handler(exportSession)
            }
        }
    }
    
    static func downloadStory(postKeys:[String], completion: @escaping (_ story:[StoryItem])->()) {
        var story = [StoryItem]()
        var loadedCount = 0
        for postKey in postKeys {
            
            getUpload(key: postKey, completion: { item in
                
                if let _ = item {
                    story.append(item!)
                }
                loadedCount += 1
                if loadedCount >= postKeys.count {
                    DispatchQueue.main.async {
                        completion(story)
                    }
                }
                
            })
        }
    }
    
    static func getUpload(key:String, completion: @escaping (_ item:StoryItem?)->()) {
        
        if let cachedUpload = uploadDataCache.object(forKey: "upload-\(key)" as NSString) as? StoryItem {
            return completion(cachedUpload)
        }
        
        let ref = Database.database().reference()
        let postRef = ref.child("uploads/meta/\(key)")
        
        postRef.observeSingleEvent(of: .value, with: { snapshot in
            var item:StoryItem?
            if snapshot.exists() {
                
                let dict = snapshot.value as! [String:AnyObject]
                
                if dict["delete"] == nil {
                    let key = key
                    guard let authorId       = dict["author"] as? String else { return completion(item) }
                    
                    let locationKey    = dict["placeID"] as? String
                    guard let downloadUrl    = dict["url"] as? String else { return completion(item) }
                    guard let url            = URL(string: downloadUrl) else { return completion(item) }
                    guard let contentTypeStr = dict["contentType"] as? String else { return completion(item) }
                    
                    let caption        = dict["caption"] as? String
                    
                    var contentType = ContentType.invalid
                    var videoURL:URL?
                    if contentTypeStr == "image" {
                        contentType = .image
                    } else if contentTypeStr == "video" {
                        contentType = .video
                        if dict["videoURL"] != nil {
                            videoURL = URL(string: dict["videoURL"] as! String)!
                        }
                    }
                    
                    guard let dateCreated = dict["timestamp"] as? Double else { return completion(item) }
                    guard let length      = dict["length"] as? Double else { return completion(item) }
                    
                    let viewers = [String:Double]()
                    let likes = [String:Double]()
                    let comments = [Comment]()
                    
                    var numViews = 0
                    if let _views = dict["views"] as? Int {
                        numViews = _views
                    }
                    
                    var numLikes = 0
                    if let _likes = dict["likes"] as? Int {
                        numLikes = _likes
                    }
                    
                    var numComments = 0
                    if let _numComments = dict["comments"] as? Int {
                        numComments = _numComments
                    }
                    
                    var numCommenters = 0
                    if let _numCommenters = dict["commenters"] as? Int {
                        numCommenters = _numCommenters
                    }
                    
                    var popularity:Double = 0
                    if let _popularity = dict["popularity"] as? Double {
                        popularity = _popularity
                    }
                    
                    var numReports = 0
                    if let _numReports = dict["reports"] as? Int {
                        numReports = _numReports
                    }
                    
                    var color:String?
                    if let hex = dict["color"] as? String {
                        color = hex
                    }
                    
                    var anon:AnonObject?
                    if let _anon = dict["anon"] as? [String:String],
                        let adjective = _anon["adjective"],
                        let animal = _anon["animal"],
                        let color = _anon["color"] {
                        
                        anon = AnonObject(adjective: adjective, animal: animal, colorHexcode: color)
                    }
                    
                    item = StoryItem(key: key, authorId: authorId, caption: caption, locationKey: locationKey, downloadUrl: url,videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, viewers: viewers, likes:likes, comments: comments, numViews: numViews, numLikes: numLikes, numComments: numComments, numCommenters: numCommenters, popularity:popularity, numReports: numReports, colorHexcode: color, anon: anon)
                    uploadDataCache.setObject(item!, forKey: "upload-\(key)" as NSString)
                }
            }
            return completion(item)
        }, withCancel: { error in
            print("Error reading Upload: \(error.localizedDescription)")
            return completion(nil)
        })

    }
    
    
    static var numConsequtiveComments = 0
    static func addComment(post:StoryItem, comment:String, completion: @escaping ((_ success:Bool)->())) {
        if comment == "" { return }
        let ref = Database.database().reference()
        
        if !UserService.isEmailVerified {
            completion(false)
            return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Please verify your email address!")
        }
        
        let now = Date()
        if let lastDate = lastCommentTime  {
            let timeSinceLastComment = now.timeIntervalSince(lastDate)
            print("Time since last comment: \(timeSinceLastComment)")
            if timeSinceLastComment < 10.0 {
                numConsequtiveComments += 1
                
                if numConsequtiveComments >= 3 {
                    lastCommentTime = Date()
                    completion(false)
                    return Alerts.showStatusWarningAlert(inWrapper: sm, withMessage: "Whoa slow down there! 😉")
                }
                
            } else {
                numConsequtiveComments = 0
            }
        }
        
        let uid = mainStore.state.userState.uid
        if userState.anonMode, let aid = userState.anonID {
            
            let uploadRef = ref.child("api/requests/anon_comment/\(uid)/\(post.key)").childByAutoId()
            let path = "api/requests/anon_comment/\(uid)/\(post.key)/\(uploadRef.key)"
            
            let updateObject = [
                "\(path)/aid" : aid,
                "\(path)/text" : comment,
                "\(path)/timestamp" : [".sv":"timestamp"],
                "uploads/subscribers/\(post.key)/\(uid)": true
                ] as [String:Any]
            
            
            ref.updateChildValues(updateObject, withCompletionBlock: { error, ref in
                
                if error != nil {
                    print("ERROR: \(error)")
                    completion(false)
                    return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to add comment.")
                } else {
                    lastCommentTime = Date()
                    completion(true)
                }
            })
            
        } else {
            let uploadRef = ref.child("uploads/comments/\(post.key)").childByAutoId()
            let path = "uploads/comments/\(post.key)/\(uploadRef.key)"
            
            let updateObject = [
                "\(path)/author" : uid,
                "\(path)/text" : comment,
                "\(path)/timestamp" : [".sv":"timestamp"],
                "uploads/subscribers/\(post.key)/\(uid)": true
                ] as [String:Any]
            
            
            ref.updateChildValues(updateObject, withCompletionBlock: { error, ref in
                
                if error != nil {
                    print("ERROR: \(error)")
                    completion(false)
                    return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to add comment.")
                } else {
                    lastCommentTime = Date()
                    completion(true)
                }
            })
        }
        
    }
    
    static func removeComment(postKey:String, commentKey:String, completion: @escaping ((_ success: Bool, _ commentKey:String)->())) {
        let ref = Database.database().reference()
        let uploadRef = ref.child("uploads/comments/\(postKey)/\(commentKey)")
        uploadRef.removeValue() { error, ref in
        
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Comment deleted!")
                return completion(true, commentKey)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to delete comment.")
                return completion(false, commentKey)
            }
        
        }
    }
    
    static func addView(post:StoryItem) {
        
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        
        
        if uid == post.authorId { return }
        if post.viewers[uid] != nil { return }
        
        post.addView(uid)
        
        let updateObject = [
            "users/viewed/\(uid)/\(post.key)": [".sv":"timestamp"],
            "uploads/views/\(post.key)/\(uid)": [".sv":"timestamp"]
        ] as [String : Any]
        
        ref.updateChildValues(updateObject) { error, ref in
        
        }
    }
    
    static func addLike(post:StoryItem) {
        
        if !UserService.isEmailVerified {
            return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Please verify your email address!")
        }
        
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        
        
        if uid == post.authorId { return }
        if post.likes[uid] != nil { return }
        
        let updateObject = [
            "users/liked/\(uid)/\(post.key)": true,
            "uploads/likes/\(post.key)/\(uid)/anon": userState.anonMode,
            "uploads/likes/\(post.key)/\(uid)/t": [".sv":"timestamp"]
            ] as [String : Any]
        
        ref.updateChildValues(updateObject) { error, ref in
            if error != nil {
                return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to add like.")
            }
        }
    }
    
    static func removeLike(post:StoryItem) {
        
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        
        
        if uid == post.authorId{ return }
        
        ref.child("users/liked/\(uid)/\(post.key)").removeValue() { error, ref in
            if error != nil {
                return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to remove like.")
            }
        }
        ref.child("uploads/likes/\(post.key)/\(uid)").removeValue() { error, ref in
            if error != nil {
                return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to remove like.")
            }
        }
    }

    
    static func deleteItem(item:StoryItem, completion: @escaping ((_ success:Bool)->())){
        let ref = Database.database().reference()

        let postRef = ref.child("uploads/meta/\(item.key)")
        postRef.removeValue { error, ref in
            if error == nil {
                uploadDataCache.removeObject(forKey: "upload-\(item.key)" as NSString)
                globalMainInterfaceProtocol?.fetchAllStories()
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Deleted!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to delete.")
                return completion(false)
            }
        }
    }
    
    static func reportItem(item:StoryItem, type:ReportType, completion:@escaping ((_ success:Bool)->())) {
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/posts/\(item.key)/\(uid)")
        let value: [String: Any] = [
            "type": type.rawValue,
            "timestamp": [".sv": "timestamp"]
        ]
        reportRef.setValue(value, withCompletionBlock: { error, ref in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Report Sent!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to send report.")
                return completion(false)
            }
        })
        
        /*
        if type == .Inappropriate {
            let uploadRef = ref.child("uploads/\(item.getKey())/flagged")
            uploadRef.setValue(true)
        }*/
    }
    
    static func editCaption(postKey:String, caption:String, completion:@escaping ((_ success:Bool)->())) {
        let ref = Database.database().reference()
        let uploadRef = ref.child("uploads/meta/\(postKey)/caption")
        Alerts.showStatusProgressAlert(inWrapper: sm, withMessage: "Updating caption...")
        uploadRef.setValue(caption) { error, ref in
            if error != nil {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to edit caption")
                return completion(false)
            }
            Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Caption edited!")
            return completion(true)
        }
    }
    
    static func reportComment(itemKey: String, commentKey:String, type:ReportType, completion:@escaping ((_ success:Bool)->())) {
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/comments/\(commentKey)/\(uid)")
        let value: [String: Any] = [
            "sender": uid,
            "itemKey": itemKey,
            "commentKey": commentKey,
            "type": type.rawValue,
            "timestamp": [".sv": "timestamp"]
        ]
        reportRef.setValue(value, withCompletionBlock: { error, ref in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Report Sent!")
                return completion(true)
            } else {
                Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to send report.")
                return completion(false)
            }
        })
    }
    
    static func subscribeToPost(withKey postKey:String, subscribe:Bool) {
        let ref = Database.database().reference()
        let uid = mainStore.state.userState.uid
        let subscribeRef = ref.child("uploads/subscribers/\(postKey)/\(uid)")
        if subscribe {
            subscribeRef.setValue(true, withCompletionBlock: { error, ref in
                if error == nil {
                    return Alerts.showStatusSuccessAlert(inWrapper: sm, withMessage: "Subscribed!")
                } else {
                    return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to subscribe.")
                }
            })
        } else {
            subscribeRef.removeValue(completionBlock: { error, ref in
                if error == nil {
                    return Alerts.showStatusDefaultAlert(inWrapper: sm, withMessage: "Unsubscribed.")
                } else {
                    return Alerts.showStatusFailAlert(inWrapper: sm, withMessage: "Unable to unsubscribe.")
                }
            })
        }
    }

}

enum ReportType:String {
    case SpamComment = "SpamComment"
    case AbusiveComment = "AbusiveComment"
    case Inappropriate = "InappropriateContent"
    case Spam          = "SpamContent"
    case InappropriateProfile = "InappropriateProfile"
    case Harassment = "Harassment"
    case Bot = "Bot"
    case Other = "Other"
    case InappropriateMessages = "InappropriateMessages"
    case SpamMessages = "SpamMessages"
}

