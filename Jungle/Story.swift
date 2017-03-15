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
}

//func findStoryByUserID(uid:String, stories:[Story]) -> Int? {
//    for i in 0 ..< stories.count {
//        if stories[i].author_uid == uid {
//            return i
//        }
//    }
//    return nil
//}
//
//func sortStoryItems(items:[StoryItem]) -> [Story] {
//    var stories = [Story]()
//    for item in items {
//        if let index = findStoryByUserID(item.getAuthorId(), stories: stories) {
//            stories[index].addItem(item)
//        } else {
//            let story = Story(author_uid: item.getAuthorId())
//            story.addItem(item)
//            stories.append(story)
//        }
//    }
//    
//    return stories
//}

//func < (lhs: Story, rhs: Story) -> Bool {
//    let lhs_item = lhs.getMostRecentItem()!
//    let rhs_item = rhs.getMostRecentItem()!
//    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedAscending
//}
//
//func == (lhs: Story, rhs: Story) -> Bool {
//    let lhs_item = lhs.getMostRecentItem()!
//    let rhs_item = rhs.getMostRecentItem()!
//    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedSame
//}
