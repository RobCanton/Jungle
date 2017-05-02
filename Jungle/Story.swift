//
//  Story.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

enum UserStoryState {
    case notLoaded, loadingItemInfo, itemInfoLoaded, loadingContent, contentLoaded
}

protocol StoryProtocol {
    func stateChange(_ state: UserStoryState)
}

class UserStory:Story {
    fileprivate var uid:String
    
    init(postKeys:[(String,Double)], uid:String) {
        self.uid = uid
        super.init(postKeys: postKeys)
    }
    
    func getUserId() -> String {
        return uid
    }
    
    
}

class LocationStory:Story {
    fileprivate var locationKey:String
    fileprivate var distance:Double
    
    init(postKeys:[(String,Double)], locationKey:String, distance:Double) {
        self.locationKey = locationKey
        self.distance = distance
        super.init(postKeys: postKeys)
    }
    
    func getLocationKey() -> String {
        return locationKey
    }
    
    func getDistance() -> Double {
        return distance
    }
    
    
}

class Story: ItemDelegate {
    fileprivate var postKeys:[(String,Double)]
    fileprivate var posts:[String]
    var delegate:StoryProtocol?
    

    var items:[StoryItem]?
    var state:UserStoryState = .notLoaded
        {
        didSet {
            delegate?.stateChange(state)
        }
    }
    
    init(postKeys:[(String,Double)]) {
        self.postKeys = postKeys
        
        self.posts = [String]()
        for (key, _) in postKeys {
            self.posts.append(key)
        }
        
        downloadItems()
    }
    
    func getPostKeys() -> [(String,Double)] {
        return postKeys
    }
    
    func getPosts() -> [String] {
        return posts
    }
    
    func determineState() {
        if needsDownload() {
            if items == nil {
                state = .notLoaded
            } else {
                state = .itemInfoLoaded
            }
        } else {
            state = .contentLoaded
        }
    }
    
    /**
     # downloadItems
     Download the full data and create a Story Item for each post key.
     
     * Successful download results set state to ItemInfoLoaded
     * If data already downloaded sets state to ContentLoaded

    */
    func downloadItems() {
        if state == .notLoaded {
            state = .loadingItemInfo
            
            UploadService.downloadStory(postKeys: posts, completion: { items in
                
                self.items = items.sorted(by: {
                    return $0 < $1
                })
                self.state = .itemInfoLoaded
                if !self.needsDownload() {
                    self.state = .contentLoaded
                }

            })
        } else if items != nil {
            if !self.needsDownload() {
                self.state = .contentLoaded
            }
        }
    }
    
    func needsDownload() -> Bool {
        if items != nil {
            for item in items! {
                if item.needsDownload() {
                    return true
                }
            }
            return false
        }
        return true
    }
    
    func itemDownloaded() {
        if !needsDownload() {
            self.state = .contentLoaded
        }
    }
    
    func downloadStory() {
        if items != nil {
            state = .loadingContent
            for item in items! {
                item.delegate = self
                item.download()
            }
        }
    }
    
    func hasViewed() -> Bool {
        for key in posts {
            if !mainStore.state.viewed.contains(key) {
                return false
            }
        }
        return true
    }
}

func < (lhs: Story, rhs: Story) -> Bool {
    let t1 = lhs.getPostKeys().first!.1
    let t2 = rhs.getPostKeys().first!.1
    return t1 < t2
}

func > (lhs: Story, rhs: Story) -> Bool {
    let t1 = lhs.getPostKeys().first!.1
    let t2 = rhs.getPostKeys().first!.1
    return t1 > t2
}

func == (lhs: Story, rhs: Story) -> Bool {
    let t1 = lhs.getPostKeys().first!.1
    let t2 = rhs.getPostKeys().first!.1
    return t1 == t2
}
