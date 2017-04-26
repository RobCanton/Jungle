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

class Upload {
    var place:GMSPlace?
    var caption:String?
    var captionPos:Double?
    var coordinates:CLLocation?
    var image:UIImage?
    var videoURL:URL?
}

let dataCache = NSCache<NSString, AnyObject>()

class UploadService {
    
    static func writeImageToFile(withKey key:String, image:UIImage) {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_image-\(key).jpg"))
        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
            try! jpgData.write(to: fileURL, options: [.atomic])
        }
    }
    
    static func readImageFromFile(withKey key:String) -> UIImage? {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_image-\(key).jpg"))
        return UIImage(contentsOfFile: fileURL.path)
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
            downloadImage(withUrl: url, completion: { image in
                if image != nil {
                    writeImageToFile(withKey: key, image: image!)
                }
                completion(image, false)
            })
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
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_video-\(key).mp4"))
        try! video.write(to: fileURL, options: [.atomic])
        return fileURL
    }
    
    static func readVideoFromFile(withKey key:String) -> URL? {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_video-\(key).mp4"))
        do {
            let _ = try Data(contentsOf: fileURL)
            
            return fileURL
        } catch let error as Error{
            print("ERROR: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    fileprivate static func downloadVideo(byAuthor author:String, withKey key:String, completion: @escaping (_ data:Data?)->()) {
        let videoRef = FIRStorage.storage().reference().child("user_uploads/videos/\(author)/\(key)")
        
        // Download in memory with a maximum allowed size of 2MB (2 * 1024 * 1024 bytes)
        videoRef.data(withMaxSize: 2 * 1024 * 1024) { (data, error) -> Void in
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

    static func sendImage(upload:Upload, completion:(()->())) {
        
        //If upload has no destination do not upload it
        if upload.image == nil { return }
        
        let ref = FIRDatabase.database().reference()
        let dataRef = ref.child("uploads/meta").childByAutoId()
        let postKey = dataRef.key
        
        let uid = mainStore.state.userState.uid
        
        if let data = UIImageJPEGRepresentation(upload.image!, 0.5) {
            // Create a reference to the file you want to upload
            // Create the file metadata
            let contentTypeStr = "image"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            // Upload file and metadata to the object
            let storageRef = FIRStorage.storage().reference()
            let uploadTask = storageRef.child("user_uploads/images/\(uid)/\(postKey)").put(data, metadata: metadata) { metadata, error in
                
                if (error != nil) {
                    // HANDLE ERROR
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()
                    var obj = [
                        "author": uid,
                        "url": downloadURL!.absoluteString,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": 6.0
                    ] as [String : Any]
                    
                    if let place = upload.place {
                        obj["placeID"] = place.placeID
                    }
                    
                    if let caption = upload.caption {
                        obj["caption"] = caption
                    }
                    
                    if let y = upload.captionPos {
                        obj["captionPos"] = y
                    }
                    
                    dataRef.setValue(obj, withCompletionBlock: { error, _ in
                        if error == nil {
                            
                            var updateValues: [String : Any] = [
                                "users/story/\(uid)/\(postKey)": [".sv": "timestamp"],
                                "users/uploads/\(uid)/\(postKey)": [".sv": "timestamp"]
                            ]
                            
                            if let place = upload.place {
                                updateValues["places/\(place.placeID)/info/name"] = place.name
                                updateValues["places/\(place.placeID)/info/lat"] = place.coordinate.latitude
                                updateValues["places/\(place.placeID)/info/lon"] = place.coordinate.longitude
                                updateValues["places/\(place.placeID)/info/address"] = place.formattedAddress
                                updateValues["places/\(place.placeID)/posts/\(postKey)"] = [".sv": "timestamp"]
                                updateValues["places/\(place.placeID)/contributers/\(uid)"] = true
                            }

                            ref.updateChildValues(updateValues, withCompletionBlock: { error, ref in
                                
                            })
                        } else {
                            
                        }
                    })
                    
                }
            }
            completion()
        }
    }
    
    static func uploadVideo(upload:Upload, completion:(_ success:Bool)->()){
        
        if upload.videoURL == nil { return }
        
        let uid = mainStore.state.userState.uid
        let url = upload.videoURL!
        
        let ref = FIRDatabase.database().reference()
        let dataRef = ref.child("uploads/meta").childByAutoId()
        let postKey = dataRef.key
        
        completion(true)
        
        uploadVideoStill(url: url, postKey: postKey, completion: { thumbURL in
            
            let data = NSData(contentsOf: url)
            
            let metadata = FIRStorageMetadata()
            let contentTypeStr = "video"
            let playerItem = AVAsset(url: url)
            let length = CMTimeGetSeconds(playerItem.duration)
            metadata.contentType = contentTypeStr
            
            let storageRef = FIRStorage.storage().reference()
            let uploadTask = storageRef.child("user_uploads/videos/\(uid)/\(postKey)").put(data as! Data, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // HANDLE ERROR

                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    
                    let downloadURL = metadata!.downloadURL()
                    var obj = [
                        "author": uid,
                        "url": thumbURL,
                        "videoURL": downloadURL!.absoluteString,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": length
                        ] as [String : Any]
                    
                    if let place = upload.place {
                        obj["placeID"] = place.placeID
                    }
                    
                    if let caption = upload.caption {
                        obj["caption"] = caption
                    }
                    
                    if let y = upload.captionPos {
                        obj["captionPos"] = y
                    }
                    
                    dataRef.setValue(obj, withCompletionBlock: { error, _ in
                        if error == nil {
                            var updateValues: [String : Any] = [
                                "users/story/\(uid)/\(postKey)": [".sv": "timestamp"],
                                "users/uploads/\(uid)/\(postKey)": [".sv": "timestamp"]
                            ]
                            
                            if let place = upload.place {
                                updateValues["places/\(place.placeID)/info/name"] = place.name
                                updateValues["places/\(place.placeID)/info/lat"] = place.coordinate.latitude
                                updateValues["places/\(place.placeID)/info/lon"] = place.coordinate.longitude
                                updateValues["places/\(place.placeID)/info/address"] = place.formattedAddress
                                updateValues["places/\(place.placeID)/posts/\(postKey)"] = [".sv": "timestamp"]
                                updateValues["places/\(place.placeID)/contributers/\(uid)"] = true
                            }
                            
                            ref.updateChildValues(updateValues, withCompletionBlock: { error, ref in
                                
                            })
                        } else {
                            
                        }
                    })
                }
            }
            
        })
    }
    
    private static func uploadVideoStill(url:URL, postKey:String, completion:@escaping (_ thumb_url:String)->()) {
        let storageRef = FIRStorage.storage().reference()
        if let videoStill = generateVideoStill(url: url) {
            if let data = UIImageJPEGRepresentation(videoStill, 0.5) {
                let stillMetaData = FIRStorageMetadata()
                stillMetaData.contentType = "image/jpg"
                let uid = mainStore.state.userState.uid
                _ = storageRef.child("user_uploads/images/\(uid)/\(postKey)").put(data, metadata: stillMetaData) { metadata, error in
                    if (error != nil) {
                        
                    } else {
                        let thumbURL = metadata!.downloadURL()!
                        completion(thumbURL.absoluteString)
                    }
                }
            }
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
        
        if let cachedUpload = dataCache.object(forKey: "upload-\(key)" as NSString) as? StoryItem {
            return completion(cachedUpload)
        }
        
        let ref = FIRDatabase.database().reference()
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
                    let captionPos    = dict["captionPos"] as? Double
                    
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
                    
                    guard let dateCreated = dict["dateCreated"] as? Double else { return completion(item) }
                    guard let length      = dict["length"] as? Double else { return completion(item) }
                    
                    var viewers = [String:Double]()
                    if snapshot.hasChild("views") {
                        viewers = dict["views"] as! [String:Double]
                    }
                   
                    var likes = [String:Double]()
                    if snapshot.hasChild("likes") {
                        likes = dict["likes"] as! [String:Double]
                    }
                    
                    var comments = [Comment]()

                    comments.sort(by: { return $0 < $1 })
                    
                    var flagged = false
                    
                    var numComments = 0
                    if let _numComments = dict["comments"] as? Int {
                        numComments = _numComments
                    }

                    item = StoryItem(key: key, authorId: authorId, caption: caption, captionPos: captionPos, locationKey: locationKey, downloadUrl: url,videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, viewers: viewers,likes:likes, comments: comments, numComments: numComments, flagged: flagged)
                    dataCache.setObject(item!, forKey: "upload-\(key)" as NSString)
                }
            }
            return completion(item)
        })
    }
    
    
    
    static func addComment(post:StoryItem, comment:String) {
        if comment == "" { return }
        let ref = FIRDatabase.database().reference()
        
        let uid = mainStore.state.userState.uid
        
        let uploadRef = ref.child("uploads/comments/\(post.getKey())").childByAutoId()
        uploadRef.setValue([
            "author": uid,
            "text":comment,
            "timestamp":[".sv":"timestamp"]
        ])
        
        // TODO
        // add completion block
    }
    
    static func addView(post:StoryItem) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        if uid == post.getAuthorId() { return }
        
        let postRef = ref.child("uploads/meta/\(post.getKey())/views/\(uid)")
        postRef.setValue([".sv":"timestamp"])
    }
    
    static func addLike(post:StoryItem) {
        
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        let postRef = ref.child("api/requests/like").childByAutoId()
        postRef.setValue([
            "sender": uid,
            "recipient": post.getAuthorId(),
            "postKey": post.getKey(),
            "isVideo": post.getContentType() == .video,
            "timestamp":[".sv":"timestamp"]
            ])
    }
    
    static func removeLike(postKey:String) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        let postRef = ref.child("uploads/\(postKey)/likes/\(uid)")
        postRef.removeValue()
    }
    
    static func deleteItem(item:StoryItem, completion: @escaping ((_ success:Bool)->())){
        let ref = FIRDatabase.database().reference()
        let postRef = ref.child("uploads/meta/\(item.getKey())")
        postRef.removeValue(completionBlock: { error, ref in
            return completion(error == nil)
        })
    }
    
    static func reportItem(item:StoryItem, type:ReportType, showNotification:Bool, completion:@escaping ((_ success:Bool)->())) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/\(uid):\(item.getKey())")
        let value: [String: Any] = [
            "sender": uid,
            "itemKey": item.getKey(),
            "type": type.rawValue,
            "timestamp": [".sv": "timestamp"]
        ]
        reportRef.setValue(value, withCompletionBlock: { error, ref in
            completion(error == nil )
        })
        
        if type == .Inappropriate {
            let uploadRef = ref.child("uploads/\(item.getKey())/flagged")
            uploadRef.setValue(true)
        }
    }

}

enum ReportType:String {
    case Inappropriate = "InappropriateContent"
    case Spam          = "SpamContent"
    case InappropriateProfile = "InappropriateProfile"
    case Harassment = "Harassment"
    case Bot = "Bot"
    case Other = "Other"
    case InappropriateMessages = "InappropriateMessages"
    case SpamMessages = "SpamMessages"
}

