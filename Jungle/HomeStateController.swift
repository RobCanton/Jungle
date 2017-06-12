//
//  HomeStateController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase

protocol HomeProtocol: class {
    func update(_ mode: SortedBy?)
}

class HomeStateController {
    weak var delegate:HomeProtocol?
    
    private(set) var nearbyPosts = [StoryItem]()
    private(set) var popularPosts = [StoryItem]()
    
    fileprivate var nearbyRef:DatabaseReference?
    fileprivate var popularRef:DatabaseReference?
    
    private(set) var followingStories = [UserStory]()
    private(set) var nearbyFollowingStories = [UserStory]()
    private(set) var popularUserStories = [UserStory]()
    private(set) var nearbyUserStories = [UserStory]()
    private(set) var recentUserStories = [UserStory]()
    
    private(set) var popularPlaceStories = [LocationStory]()
    private(set) var recentPlaceStories = [LocationStory]()
    private(set) var nearbyPlaceStories = [LocationStory]()
    
    
    fileprivate var myStoryRef:DatabaseReference?
    fileprivate var followingRef:DatabaseReference?
    fileprivate var nearbyFollowingRef:DatabaseReference?
    fileprivate var popularUsersRef:DatabaseReference?
    fileprivate var nearbyUsersRef:DatabaseReference?
    fileprivate var recentUsersRef:DatabaseReference?
    
    fileprivate var popularPlacesRef:DatabaseReference?
    fileprivate var nearbyPlacesRef:DatabaseReference?
    fileprivate var recentPlacesRef:DatabaseReference?
    
    init(delegate:HomeProtocol)
    {
        self.delegate = delegate
        
        fetchAll()
    }
    
    func clear() {
        
        followingStories = [UserStory]()
        nearbyFollowingStories = [UserStory]()
        popularUserStories = [UserStory]()
        nearbyUserStories = [UserStory]()
        recentUserStories = [UserStory]()
        
        popularPlaceStories = [LocationStory]()
        recentPlaceStories = [LocationStory]()
        nearbyPlaceStories = [LocationStory]()
        
        myStoryRef?.removeAllObservers()
        followingRef?.removeAllObservers()
        nearbyFollowingRef?.removeAllObservers()
        popularUsersRef?.removeAllObservers()
        recentUsersRef?.removeAllObservers()
        popularPlacesRef?.removeAllObservers()
        nearbyPlacesRef?.removeAllObservers()
        recentPlacesRef?.removeAllObservers()
        
        myStoryRef = nil
        followingRef = nil
        nearbyFollowingRef = nil
        popularUsersRef = nil
        recentUsersRef = nil
        popularPlacesRef = nil
        nearbyPlacesRef = nil
        recentPlacesRef = nil
    }
    
    func fetchAll() {
        observeNearbyPosts()
        observePopularPosts()
        fetchFollowing()
    }

    
    func sortFollowingByDate() {
        followingStories.sort(by: { $0 > $1})
        let uid = mainStore.state.userState.uid
        var swapIndex:Int?
        for i in 0..<followingStories.count {
            let story = followingStories[i]
            if story.uid == uid {
                swapIndex = i
                break
            }
        }
        if swapIndex != nil {
            let swapStory = followingStories[swapIndex!]
            followingStories.remove(at: swapIndex!)
            followingStories.insert(swapStory, at: 0)
        }
    }
    
    
    fileprivate func fetchFollowing() {
        let uid = mainStore.state.userState.uid
        followingRef?.removeAllObservers()
        followingRef = UserService.ref.child("social/following/\(uid)")
        followingRef?.observe(.value, with: { snapshot in
            var following:[String] = [uid] // Include current user id to pull my story
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                following.append(childSnap.key)
            }
            
            self.downloadFollowingStories(following)
        })
    }
    
    fileprivate func downloadFollowingStories(_ following:[String]) {
        var stories = [UserStory]()
        if following.count == 0 {
            delegate?.update(.Recent)
            return
        }
        var count = 0
        for uid in following {
            UserService.getUserStory(uid, completion: { story in
                if story != nil {
                    stories.append(story!)
                }
                count += 1
                if count >= following.count {
                    count = -1
                    let uid = mainStore.state.userState.uid
                    self.followingStories = stories.sorted(by: { return $0 > $1 })
                    
                    print("stories: \(self.followingStories.count)")
                    DispatchQueue.main.async {
                        self.delegate?.update(.Recent)
                    }
                }
            })
        }
    }
    
    
    fileprivate func observeNearbyPosts() {
        let uid = mainStore.state.userState.uid
        nearbyRef?.removeAllObservers()
        nearbyRef = UserService.ref.child("users/location/nearby/\(uid)/posts")
        nearbyRef?.queryOrderedByValue().observe(.value, with: { snapshot in
            var posts = [String]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                let key = childSnap.key
                if let _ = childSnap.value as? Double {
                    posts.append(key)
                }
            }
            self.downloadPosts(posts)
        })
    }
    
    fileprivate func downloadPosts(_ posts:[String]) {
        var nearbyPosts = [StoryItem]()
        if posts.count == 0 {
            delegate?.update(.Nearby)
            return
        }
        
        var count = 0
        for key in posts {
            UploadService.getUpload(key: key, completion: { item in
                if item != nil {
                    nearbyPosts.append(item!)
                }
                
                count += 1
                if count >= posts.count {
                    count = -1
                    
                    self.nearbyPosts = nearbyPosts.sorted(by: { return $0 > $1 })
                    DispatchQueue.main.async {
                        self.delegate?.update(.Nearby)
                    }
                }
                
            })
        }
    }
    
    fileprivate func observePopularPosts() {
        popularRef?.removeAllObservers()
        popularRef = UserService.ref.child("uploads/popular/")
        popularRef?.queryOrderedByValue().queryLimited(toLast: 25).observe(.value, with: { snapshot in
            var posts = [String]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                let key = childSnap.key
                if let d = childSnap.value as? Double {
                    posts.append(key)
                }
            }
        
            self.downloadPopularPosts(posts)
        })
    }
    
    fileprivate func downloadPopularPosts(_ posts:[String]) {
        var popularPosts = [StoryItem]()
        
        if posts.count == 0 {
            delegate?.update(.Popular)
            return
        }
        
        var count = 0
        for key in posts {
            UploadService.getUpload(key: key, completion: { item in
                if item != nil {
                    popularPosts.append(item!)
                }
                
                count += 1
                if count >= posts.count {
                    count = -1
                    
                    self.popularPosts = popularPosts.sorted(by: { return $0.popularity > $1.popularity })
                    DispatchQueue.main.async {
                        self.delegate?.update(.Popular)
                    }
                }
                
            })
        }
    }
}
