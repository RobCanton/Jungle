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

protocol StoryProtocol: class {
    func stateChange(_ state: UserStoryState)
}


class UserStory:Story {
    private(set) var uid:String
    
    init(postKeys:[(String,Double)], uid:String) {
        self.uid = uid
        super.init(postKeys: postKeys)
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
    
    private(set) var lastPostKey:String
    private(set) var date:Date
    var count:Int {
        get {
            return posts.count
        }
    }
    
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
        
        self.lastPostKey = postKeys.last!.0
        self.date = Date(timeIntervalSince1970: postKeys.last!.1/1000) as Date
        
        downloadItems()
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
    
    func printDescription() {

        for key in posts {
            print(" * \(key)")
        }
        
        print("\n")
    }
}

func < (lhs: Story, rhs: Story) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

func > (lhs: Story, rhs: Story) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedDescending
}

func == (lhs: Story, rhs: Story) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedSame
}
