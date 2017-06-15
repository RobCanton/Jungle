//
//  StoryItem.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation

protocol ItemDelegate {
    func itemDownloaded()
}

enum ContentType:Int {
    case image = 1
    case video = 2
    case invalid =  0
}


class StoryItem: NSObject, NSCoding {
    
    private(set) var key:String                    // Key in database
    private(set) var authorId:String
    private(set) var caption:String?
    private(set) var locationKey:String?
    private(set) var downloadUrl:URL
    private(set) var videoURL:URL?
    private(set) var contentType:ContentType
    private(set) var dateCreated: Date
    private(set) var length: Double
    private(set) var popularity:Double
    
    private(set) var numComments:Int
    private(set) var numCommenters:Int
    var numLikes:Int {
        didSet {
            cache()
        }
    }
    private(set) var numViews:Int
    
    private(set) var numReports:Int

    
    var viewers:[String:Double]
    var likes:[String:Double]
    var comments:[Comment]
    
    var delegate:ItemDelegate?
    
    fileprivate var colorHexcode:String?

    dynamic var videoFilePath: URL?
    dynamic var videoData:Data?
    
    init(key: String, authorId: String, caption:String?, locationKey:String?, downloadUrl: URL, videoURL:URL?, contentType: ContentType, dateCreated: Double, length: Double,
         viewers:[String:Double], likes:[String:Double], comments: [Comment], numViews:Int, numLikes:Int, numComments:Int, numCommenters:Int, popularity:Double,  numReports:Int, colorHexcode:String?)
    {
        
        self.key          = key
        self.authorId     = authorId
        self.caption      = caption
        self.locationKey  = locationKey
        self.downloadUrl  = downloadUrl
        self.videoURL     = videoURL
        self.contentType  = contentType
        self.dateCreated  = Date(timeIntervalSince1970: dateCreated/1000) as Date
        self.length       = length
        self.viewers      = viewers
        self.likes        = likes
        self.comments     = comments
        self.numViews     = numViews
        self.numLikes     = numLikes
        self.numComments  = numComments
        self.numCommenters = numCommenters
        self.popularity   = popularity
        self.numReports   = numReports
        self.colorHexcode = colorHexcode
        
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key         = decoder.decodeObject(forKey: "key") as! String
        let authorId    = decoder.decodeObject(forKey: "authorId") as! String
        let caption     = decoder.decodeObject(forKey: "caption") as? String
        let locationKey = decoder.decodeObject(forKey: "locationKey") as? String
        let downloadUrl = decoder.decodeObject(forKey: "downloadUrl") as! URL
        let ctInt       = decoder.decodeObject(forKey: "contentType") as! Int
        let dateCreated = decoder.decodeObject(forKey: "dateCreated") as! Double
        let length      = decoder.decodeObject(forKey: "length") as! Double
        let videoURL    = decoder.decodeObject(forKey: "videoURL") as? URL
        let flagged     = decoder.decodeObject(forKey: "flagged") as! Bool
        let numViews    = decoder.decodeObject(forKey: "numViews") as! Int
        let numLikes    = decoder.decodeObject(forKey: "numLikes") as! Int
        let numComments = decoder.decodeObject(forKey: "numComments") as! Int
        let numCommenters = decoder.decodeObject(forKey: "numCommenters") as! Int
        let popularity      = decoder.decodeObject(forKey: "popularity") as! Double
        let numReports = decoder.decodeObject(forKey: "numReports") as! Int
        let colorHexcode    = decoder.decodeObject(forKey: "color") as? String
        var viewers = [String:Double]()
        if let _viewers = decoder.decodeObject(forKey: "viewers") as? [String:Double] {
            viewers = _viewers
        }
        
        var likes = [String:Double]()
        if let _likes = decoder.decodeObject(forKey: "likes") as? [String:Double] {
            likes = _likes
        }
        
        var comments = [Comment]()
        if let _comments = decoder.decodeObject(forKey: "comments") as? [Comment] {
            comments = _comments
        }
        
        var contentType:ContentType = .invalid
        switch ctInt {
        case 1:
            contentType = .image
            break
        case 2:
            contentType = .video
            break
        default:
            break
        }
        
        self.init(key: key, authorId: authorId, caption: caption, locationKey:locationKey, downloadUrl: downloadUrl, videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, viewers: viewers, likes: likes, comments: comments, numViews: numViews, numLikes: numLikes, numComments: numComments, numCommenters: numCommenters, popularity: popularity, numReports: numReports, colorHexcode: colorHexcode)
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(authorId, forKey: "authorId")
        if locationKey != nil {
            coder.encode(locationKey!, forKey: "locationKey")
        }
        if caption != nil {
            coder.encode(caption!, forKey: "caption")
        }
        
        coder.encode(downloadUrl, forKey: "downloadUrl")
        coder.encode(contentType.rawValue, forKey: "contentType")
        coder.encode(dateCreated, forKey: "dateCreated")
        coder.encode(length, forKey: "length")
        coder.encode(viewers, forKey: "viewers")
        coder.encode(likes, forKey: "likes")
        coder.encode(comments, forKey: "comments")
        if videoURL != nil {
            coder.encode(videoURL!, forKey: "videoURL")
        }
        
        coder.encode(numComments, forKey: "numComments")
        coder.encode(numViews, forKey: "numViews")
        coder.encode(numLikes, forKey: "numLikes")
        coder.encode(numReports, forKey: "numReports")
        coder.encode(popularity, forKey: "popularity")
        coder.encode(colorHexcode, forKey: "colorHexcode")
    }
    
    
    
    func getViewsList() -> [String] {
        var list = [String]()
        for (uid, _) in viewers {
            list.append(uid)
        }
        return list
    }
    
    func needsDownload() -> Bool{
        if contentType == .image {
            return !UploadService.imageFileExists(withKey: key)
        }
        
        if contentType == .video {
            return !UploadService.videoFileExists(withKey: key)
        }  
        return true
    }
    
    func download() {
        UploadService.retrieveImage(byKey: key, withUrl: downloadUrl, completion: { image, fromFile in
            if self.contentType == .image {
                self.delegate?.itemDownloaded()
            } else if self.contentType == .video {
                if let _ = UploadService.readVideoFromFile(withKey: self.key) {
                    self.delegate?.itemDownloaded()
                } else {
                    UploadService.retrieveVideo(byAuthor: self.authorId, withKey: self.key, completion: { data in
                        self.delegate?.itemDownloaded()
                    })
                }
            }
        })
    }
    
    func addView(_ uid:String) {
        self.viewers[uid] = 0
        cache()
    }
    
    func addComment(_ comment:Comment) {
        for _comment in comments {
            if _comment.key == comment.key { return }
        }
        
        self.comments.append(comment)
        self.numComments = self.comments.count
        cache()
    }
    
    func removeComment(key:String) {
        var removeIndex:Int?
        for i in 0..<comments.count {
            if comments[i].key == key {
                removeIndex = i
                break
            }
        }
        
        if removeIndex != nil {
            comments.remove(at: removeIndex!)
        }
        
        self.numComments = self.comments.count
        
        cache()
    }
    
    func addLike(_ uid:String) {
        self.likes[uid] = 0
        cache()
    }
    
    func removeLike(_ uid:String) {
        self.likes[uid] = nil
        cache()
    }

    
    func updateNumComments(_ count:Int) {
        self.numComments = count
        cache()
    }
    
    func getColor() -> UIColor? {
        if colorHexcode != nil {
           return hexStringToUIColor(hex: colorHexcode!)
        }
        return nil
    }
    
    func editCaption(caption:String) {
        self.caption = caption
        cache()
    }
    
    func cache() {
        dataCache.removeObject(forKey: "upload-\(key)" as NSString)
        dataCache.setObject(self, forKey: "upload-\(key)" as NSString)
    }
    
    var shouldBlock:Bool {
        get {
            print("\(numReports) : \(mainStore.state.settingsState.allowFlaggedContent)")
            return numReports > 0 && !mainStore.state.settingsState.allowFlaggedContent
        }
    }
    
}

func < (lhs: StoryItem, rhs: StoryItem) -> Bool {
    return lhs.dateCreated.compare(rhs.dateCreated) == .orderedAscending
}

func > (lhs: StoryItem, rhs: StoryItem) -> Bool {
    return lhs.dateCreated.compare(rhs.dateCreated) == .orderedDescending
}

func == (lhs: StoryItem, rhs: StoryItem) -> Bool {
    return lhs.dateCreated.compare(rhs.dateCreated) == .orderedSame
}
