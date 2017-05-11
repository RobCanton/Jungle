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
    
    init(posts:[String], lastPostKey:String, timestamp:Double, popularity:Int, uid:String) {
        self.uid = uid
        super.init(posts:posts, lastPostKey:lastPostKey, timestamp:timestamp, popularity:popularity)
    }
    
    func getUserId() -> String {
        return uid
    }
    override func printDescription() {
        print("USER STORY: \(uid)")
        super.printDescription()
    }
    
    
}

class LocationStory:Story {
    fileprivate var locationKey:String
    
    init(posts:[String], lastPostKey:String, timestamp:Double, popularity:Int, locationKey:String) {
        self.locationKey = locationKey
        super.init(posts:posts, lastPostKey:lastPostKey, timestamp:timestamp, popularity:popularity)
    }
    
    func getLocationKey() -> String {
        return locationKey
    }
    
}

class Story: ItemDelegate {
    private(set) var posts:[String]
    private(set) var lastPostKey:String
    private(set) var date:Date
    private(set) var popularity:Int
    var distance:Double?
    var delegate:StoryProtocol?
    

    var items:[StoryItem]?
    var state:UserStoryState = .notLoaded
        {
        didSet {
            delegate?.stateChange(state)
        }
    }
    
    init(posts:[String], lastPostKey:String, timestamp:Double, popularity:Int) {
        
        self.posts = posts
        self.lastPostKey = lastPostKey
        self.date = Date(timeIntervalSince1970: timestamp/1000) as Date
        self.popularity = popularity

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
