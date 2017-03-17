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
    var caption:String = ""
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
                    
                    let image = UIImage(data: data!)
                    return completion(image!)
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
        guard let place = upload.place else { return }
        if upload.image == nil { return }
        
        let ref = FIRDatabase.database().reference()
        let dataRef = ref.child("uploads").childByAutoId()
        let postKey = dataRef.key
        
        guard let user = FIRAuth.auth()?.currentUser else { return }
        
        let uid = user.uid
        
        if let data = UIImageJPEGRepresentation(upload.image!, 0.5) {
            for component in place.addressComponents! {
                print("TYPE: \(component.type) : \(component.name)")
            }
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
                    let obj = [
                        "author": uid,
                        "caption": upload.caption,
                        "placeID": place.placeID,
                        "url": downloadURL!.absoluteString,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": 6.0
                    ] as [String : Any]
                    
                    
                    
                    
                    dataRef.setValue(obj, withCompletionBlock: { error, _ in
                        if error == nil {
                            
                            let updateValues: [String : Any] = [
                                "info/name": place.name,
                                "info/lat": place.coordinate.latitude,
                                "info/lon": place.coordinate.longitude,
                                "info/address": place.formattedAddress,
                                "posts/\(postKey)": [".sv": "timestamp"],
                                "contributers/\(uid)": true
                            ]

                            let placeRef = ref.child("places/\(place.placeID)")
                            placeRef.updateChildValues(updateValues, withCompletionBlock: { error, ref in
                                
                            })
                        } else {
                            
                        }
                    })
                    
                }
            }
            completion()
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
        let postRef = ref.child("uploads/\(key)")
        
        postRef.observeSingleEvent(of: .value, with: { snapshot in
            
            var item:StoryItem?
            if snapshot.exists() {
                
                let dict = snapshot.value as! [String:AnyObject]
                
                if dict["delete"] == nil {
                    let key = key
                    guard let authorId       = dict["author"] as? String else { return completion(item) }
                    guard let caption        = dict["caption"] as? String else { return completion(item) }
                    guard let locationKey    = dict["placeID"] as? String else { return completion(item) }
                    guard let downloadUrl    = dict["url"] as? String else { return completion(item) }
                    guard let url            = URL(string: downloadUrl) else { return completion(item) }
                    guard let contentTypeStr = dict["contentType"] as? String else { return completion(item) }
                    
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
                   
                    var likes = [String:Double]()
                    
                    var comments = [Comment]()
                    if snapshot.hasChild("comments") {
                        let commentsDict = dict["comments"] as! [String:AnyObject]
                        for (key, object) in commentsDict {
                            let key = key
                            let author = object["author"] as! String
                            let text = object["text"] as! String
                            let timestamp = object["timestamp"] as! Double
                            
                            let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                            comments.append(comment)
                        }
                    }
                    
                    comments.sort(by: { return $0 < $1 })
                    
                    var flagged = false

                    item = StoryItem(key: key, authorId: authorId, caption: caption, locationKey: locationKey, downloadUrl: url,videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, viewers: viewers,likes:likes, comments: comments, flagged: flagged)
                    dataCache.setObject(item!, forKey: "upload-\(key)" as NSString)
                }
            }
            return completion(item)
        })
    }
    
    static func addComment(post:StoryItem, comment:String) {
        if comment == "" { return }
        let ref = FIRDatabase.database().reference()
        
        guard let user = FIRAuth.auth()?.currentUser else { return }
        
        let uid = user.uid

        let postRef = ref.child("api/requests/comment").childByAutoId()
        postRef.setValue([
            "sender": uid,
            "recipient": post.getAuthorId(),
            "postKey": post.getKey(),
            "text":comment,
            "timestamp":[".sv":"timestamp"]
        ])
    }
    
    

}



let imageCache = NSCache<NSString, UIImage>()

func loadImageUsingCacheWithURL(_ _url:String, completion: @escaping (_ image:UIImage?, _ fromCache:Bool)->()) {
    // Check for cached image
    if let cachedImage = imageCache.object(forKey: _url as NSString) {
        return completion(cachedImage, true)
    } else {
        downloadImageWithURLString(_url, completion: completion)
    }
}

func loadImageCheckingCache(withUrl _url:String, check:Int, completion: @escaping (_ image:UIImage?, _ fromCache:Bool, _ check:Int)->()) {
    // Check for cached image
    if let cachedImage = imageCache.object(forKey: _url as NSString) {
        return completion(cachedImage, true, check)
    } else {
        downloadImage(withUrl: _url, check: check, completion: completion)
    }
}

func downloadImageWithURLString(_ _url:String, completion: @escaping (_ image:UIImage?, _ fromCache:Bool)->()) {
    
    let url = URL(string: _url)
    
    URLSession.shared.dataTask(with: url!, completionHandler:
        { (data, response, error) in
            
            //error
            if error != nil {
                if error?._code == -999 {
                    return
                }
                //print(error?.code)
                return completion(nil, false)
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: _url as NSString)
                }
                
                let image = UIImage(data: data!)
                return completion(image!, false)
            }
            
    }).resume()
}

func downloadImage(withUrl _url:String, check:Int, completion: @escaping (_ image:UIImage?, _ fromCache:Bool, _ check:Int)->()) {
    
    let url = URL(string: _url)
    
    URLSession.shared.dataTask(with: url!, completionHandler:
        { (data, response, error) in
            
            //error
            if error != nil {
                if error?._code == -999 {
                    return
                }
                //print(error?.code)
                return completion(nil, false, check)
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: _url as NSString)
                }
                
                let image = UIImage(data: data!)
                return completion(image!, false, check)
            }
            
    }).resume()
}

