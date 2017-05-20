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
    
    private(set) var myStory = UserStory(posts: [], lastPostKey: "", timestamp: 0, popularity: 0, uid: "")
    
    private(set) var followingStories = [UserStory]()
    private(set) var nearbyFollowingStories = [UserStory]()
    private(set) var popularUserStories = [UserStory]()
    private(set) var nearbyUserStories = [UserStory]()
    private(set) var recentUserStories = [UserStory]()
    
    private(set) var popularPlaceStories = [LocationStory]()
    private(set) var recentPlaceStories = [LocationStory]()
    private(set) var nearbyPlaceStories = [LocationStory]()
    
    
    fileprivate var myStoryRef:FIRDatabaseReference?
    fileprivate var followingRef:FIRDatabaseReference?
    fileprivate var nearbyFollowingRef:FIRDatabaseReference?
    fileprivate var popularUsersRef:FIRDatabaseReference?
    fileprivate var nearbyUsersRef:FIRDatabaseReference?
    fileprivate var recentUsersRef:FIRDatabaseReference?
    
    fileprivate var popularPlacesRef:FIRDatabaseReference?
    fileprivate var nearbyPlacesRef:FIRDatabaseReference?
    fileprivate var recentPlacesRef:FIRDatabaseReference?
    
    init(delegate:HomeProtocol)
    {
        self.delegate = delegate
        
        fetchAll()
    }
    
    func fetchAll() {
        observeMyStory()
        
        fetchFollowing()
        
        fetchPopularUsers()
        fetchPopularPlaces()
        
        fetchRecentUsers()
        fetchRecentPlaces()
        
        observeNearbyFollowing()
        observeNearbyUsers()
        observeNearbyPlaces()
    }
    
    func sortFollowingByDate() {
        followingStories.sort(by: { $0 > $1})
        let uid = mainStore.state.userState.uid
        var swapIndex:Int?
        for i in 0..<followingStories.count {
            let story = followingStories[i]
            if story.getUserId() == uid {
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
    
    func sortFollowingByPopularity() {
        followingStories.sort(by: { $0.popularity > $1.popularity })
        let uid = mainStore.state.userState.uid
        var swapIndex:Int?
        for i in 0..<followingStories.count {
            let story = followingStories[i]
            if story.getUserId() == uid {
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

    fileprivate func observeMyStory() {
        let uid = mainStore.state.userState.uid
        myStoryRef?.removeAllObservers()
        myStoryRef = UserService.ref.child("stories/users/\(uid)")
        myStoryRef?.observe(.value, with: { snapshot in
            var story:UserStory?
            print("MY STORY UPDATED")
            if let dict = snapshot.value as? [String:AnyObject] {
                if let meta = dict["meta"] as? [String:AnyObject], let postObject = dict["posts"] as? [String:AnyObject] {
                    let lastPost = meta["k"] as! String
                    let timestamp = meta["t"] as! Double
                    var popularity = 0
                    if let p = meta["p"] as? Int {
                        popularity = p
                    }
                    var posts = [String]()
                    for (key,_) in postObject {
                        posts.append(key)
                    }
                    story = UserStory(posts: posts, lastPostKey: lastPost, timestamp: timestamp, popularity:popularity, uid: snapshot.key)
                }
            }
            if story == nil {
                story = UserStory(posts: [], lastPostKey: "", timestamp: 0, popularity: 0, uid: "")
            }
            
            self.myStory = story!
            self.myStory.printDescription()
            DispatchQueue.main.async {
                print("LIKE WHATS GOOD")
                self.delegate?.update(nil)
            }
        })
    }
    
    fileprivate func fetchFollowing() {
        let uid = mainStore.state.userState.uid
        followingRef = UserService.ref.child("social/following/\(uid)")
        followingRef?.observeSingleEvent(of: .value, with: { snapshot in
            var following:[String] = [] // Include current user id to pull my story
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                following.append(childSnap.key)
            }
            self.downloadFollowingStories(following)
        })
    }
    
    fileprivate func downloadFollowingStories(_ following:[String]) {
        var stories = [UserStory]()
        
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
                    var temp = stories.sorted(by: { return $0.popularity > $1.popularity})
                    var swapIndex:Int?
                    for i in 0..<temp.count {
                        let story = temp[i]
                        if story.getUserId() == uid {
                        
                            swapIndex = i
                            break
                        }
                    }
                    if swapIndex != nil {
                        let swapStory = temp[swapIndex!]
                        temp.remove(at: swapIndex!)
                        temp.insert(swapStory, at: 0)
                    }
                    self.followingStories = temp
                    DispatchQueue.main.async {
                        self.delegate?.update(nil)
                    }
                }
            })
        }
    }
    
    fileprivate func fetchPopularUsers() {
        popularUsersRef?.removeAllObservers()
        popularUsersRef = UserService.ref.child("stories/sorted/popular/userStories")
        popularUsersRef?.queryOrderedByValue().queryLimited(toLast: 25).observeSingleEvent(of: .value, with: { snapshot in
            var stories = [(String,Int)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                if let score = childSnap.value as? Int, !mainStore.state.socialState.following.contains(key) {
                    stories.append((key,score))
                }
            }
            self.downloadPopularStories(stories)
        })
    }
    
    fileprivate func downloadPopularStories(_ popular:[(String,Int)]) {
        var stories = [UserStory]()
        
        var count = 0
        for pair in popular {
            UserService.getUserStory(pair.0, completion: { story in
                if story != nil {
                    stories.append(story!)
                }
                count += 1
                if count >= popular.count {
                    count = -1
                    
                    self.popularUserStories = stories.sorted(by: { return $0.popularity > $1.popularity})
                    DispatchQueue.main.async {
                        self.delegate?.update(.Popular)
                    }
                }
            })
        }
    }
    
    fileprivate func observeNearbyFollowing() {
        let uid = mainStore.state.userState.uid
        nearbyFollowingRef?.removeAllObservers()
        nearbyFollowingRef = UserService.ref.child("users/location/nearby/\(uid)/following")
        nearbyFollowingRef?.queryOrderedByValue().queryLimited(toLast: 25).observe(.value, with: { snapshot in
            var stories: [(String,Double)] = []
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                if let distance = childSnap.value as? Double {
                    stories.append((key,distance))
                }
            }
            self.downloadNearbyFollowingStories(stories)
        })
    }
    
    fileprivate func downloadNearbyFollowingStories(_ nearby:[(String,Double)]) {
        var stories = [UserStory]()
        
        var count = 0
        for (key, distance) in nearby {
            UserService.getUserStory(key, completion: { story in
                if story != nil {
                    story!.distance = distance
                    stories.append(story!)
                }
                count += 1
                if count >= nearby.count {
                    count = -1
                    let uid = mainStore.state.userState.uid
                    var temp = stories.sorted(by: { return $0.distance! < $1.distance!})
                    var swapIndex:Int?
                    for i in 0..<temp.count {
                        let story = temp[i]
                        if story.getUserId() == uid {
                            
                            swapIndex = i
                            break
                        }
                    }
                    if swapIndex != nil {
                        let swapStory = temp[swapIndex!]
                        temp.remove(at: swapIndex!)
                        temp.insert(swapStory, at: 0)
                    }
                    
                    self.nearbyFollowingStories = temp
                    DispatchQueue.main.async {
                        self.delegate?.update(.Nearby)
                    }
                }
            })
        }
    }
    
    fileprivate func observeNearbyUsers() {
        let uid = mainStore.state.userState.uid
        nearbyUsersRef?.removeAllObservers()
        nearbyUsersRef = UserService.ref.child("users/location/nearby/\(uid)/users")
        nearbyUsersRef?.queryOrderedByValue().queryLimited(toLast: 25).observe(.value, with: { snapshot in
            var stories = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                
                if let distance = childSnap.value as? Double, !mainStore.state.socialState.following.contains(key), key != uid {
                    stories.append((key,distance))
                }
            }
            self.downloadNearbyUserStories(stories)
        })
    }
    
    fileprivate func downloadNearbyUserStories(_ nearby:[(String,Double)]) {
        var stories = [UserStory]()
        
        var count = 0
        for (key, distance) in nearby {
            UserService.getUserStory(key, completion: { story in
                if story != nil {
                    story!.distance = distance
                    stories.append(story!)
                }
                count += 1
                if count >= nearby.count {
                    count = -1
                    
                    self.nearbyUserStories = stories.sorted(by: { return $0.distance! < $1.distance!})
                    DispatchQueue.main.async {
                        self.delegate?.update(.Nearby)
                    }
                }
            })
        }
    }
    
    
    fileprivate func observeNearbyPlaces() {
        let uid = mainStore.state.userState.uid
        nearbyPlacesRef?.removeAllObservers()
        nearbyPlacesRef = UserService.ref.child("users/location/nearby/\(uid)/places")
        nearbyPlacesRef?.queryOrderedByValue().queryLimited(toLast: 25).observe(.value, with: { snapshot in
            var stories = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                if let distance = childSnap.value as? Double, key != mainStore.state.userState.uid {
                    stories.append((key,distance))
                }
            }
            self.downloadNearbyPlacesStories(stories)
        })
    }
    
    fileprivate func downloadNearbyPlacesStories(_ nearby:[(String,Double)]) {
        var stories = [LocationStory]()
        
        var count = 0
        for (key,distance) in nearby {
            UserService.getPlaceStory(key, completion: { story in
                if story != nil {
                    
                    story!.distance = distance
                    stories.append(story!)
                }
                count += 1
                if count >= nearby.count {
                    count = -1
                    
                    self.nearbyPlaceStories = stories.sorted(by: { return $0.distance! < $1.distance!})
                    DispatchQueue.main.async {
                        self.delegate?.update(.Nearby)
                    }
                }
            })
        }
    }
    
    fileprivate func fetchRecentUsers() {
        
        recentUsersRef = UserService.ref.child("stories/sorted/recent/userStories")
        recentUsersRef?.queryOrderedByValue().queryLimited(toLast: 25).observeSingleEvent(of: .value, with: { snapshot in
            var stories = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                if let score = childSnap.value as? Double, !mainStore.state.socialState.following.contains(key), key != mainStore.state.userState.uid {
                    stories.append((key,score))
                }
            }
            self.downloadRecentStories(stories)
        })
    }
    
    fileprivate func downloadRecentStories(_ recent:[(String,Double)]) {
        var stories = [UserStory]()
        
        var count = 0
        for pair in recent {
            UserService.getUserStory(pair.0, completion: { story in
                if story != nil {
                    stories.append(story!)
                }
                count += 1
                if count >= recent.count {
                    count = -1
                    
                    self.recentUserStories = stories.sorted(by: { return $0 > $1})
                    DispatchQueue.main.async {
                        self.delegate?.update(.Recent)
                    }
                }
            })
        }
    }
    
    fileprivate func fetchPopularPlaces() {
        popularPlacesRef?.removeAllObservers()
        popularPlacesRef = UserService.ref.child("stories/sorted/popular/places")
        popularPlacesRef?.queryOrderedByValue().queryLimited(toLast: 25).observeSingleEvent(of: .value, with: { snapshot in
            var stories = [(String,Double)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                if let score = childSnap.value as? Double, !mainStore.state.socialState.following.contains(key) {
                    stories.append((key,score))
                }
            }
            self.downloadPlacesStories(stories)
        })
    }
    
    fileprivate func downloadPlacesStories(_ popular:[(String,Double)]) {
        var stories = [LocationStory]()
        
        var count = 0
        for pair in popular {
            UserService.getPlaceStory(pair.0, completion: { story in
                if story != nil {
                    stories.append(story!)
                }
                count += 1
                if count >= popular.count {
                    count = -1
                    
                    self.popularPlaceStories = stories.sorted(by: { return $0.popularity > $1.popularity})
                    DispatchQueue.main.async {
                        self.delegate?.update(.Popular)
                    }
                }
            })
        }
    }
    
    fileprivate func fetchRecentPlaces() {
        recentPlacesRef?.removeAllObservers()
        recentPlacesRef = UserService.ref.child("stories/sorted/recent/places")
        recentPlacesRef?.queryOrderedByValue().queryLimited(toLast: 25).observeSingleEvent(of: .value, with: { snapshot in
            var stories = [String]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                stories.append(key)
            }
            self.downloadRecentPlacesStories(stories)
        })
    }
    
    fileprivate func downloadRecentPlacesStories(_ recent:[String]) {
        var stories = [LocationStory]()
        
        var count = 0
        for key in recent {
            UserService.getPlaceStory(key, completion: { story in
                if story != nil {
                    stories.append(story!)
                }
                count += 1
                if count >= recent.count {
                    count = -1
                    
                    self.recentPlaceStories = stories.sorted(by: { return $0 > $1})
                    DispatchQueue.main.async {
                        self.delegate?.update(.Recent)
                    }
                }
            })
        }
    }
    
    
}
