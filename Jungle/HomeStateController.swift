//
//  HomeStateController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase

protocol HomeProtocol {
    func update(_ mode: SortedBy?)
}

class HomeStateController {
    var delegate:HomeProtocol?
    
    private(set) var myStory:UserStory?
    private(set) var followingStories = [UserStory]()
    private(set) var popularUserStories = [UserStory]()
    private(set) var recentUserStories = [UserStory]()
    private(set) var popularPlaceStories = [LocationStory]()
    private(set) var recentPlaceStories = [LocationStory]()
    
    
    fileprivate var followingRef:FIRDatabaseReference?
    fileprivate var popularUsersRef:FIRDatabaseReference?
    fileprivate var recentUsersRef:FIRDatabaseReference?
    fileprivate var popularPlacesRef:FIRDatabaseReference?
    fileprivate var recentPlacesRef:FIRDatabaseReference?
    
    init(delegate:HomeProtocol)
    {
        self.delegate = delegate
        
        observeFollowing()
        observePopularUsers()
        observeRecentUsers()
        observePopularPlaces()
        observeRecentPlaces()
        
    }
    
    func sortFollowingByDate() {
        followingStories.sort(by: { $0 > $1})
    }
    
    func sortFollowingByPopularity() {
        followingStories.sort(by: { $0.popularity > $1.popularity })
    }

    fileprivate func observeFollowing() {
        let uid = mainStore.state.userState.uid
        followingRef?.removeAllObservers()
        followingRef = UserService.ref.child("users/social/following/\(uid)")
        followingRef?.observe(.value, with: { snapshot in
            var following = [String]()
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
                    
                    self.followingStories = stories.sorted(by: { return $0.popularity > $1.popularity})
                    DispatchQueue.main.async {
                        self.delegate?.update(nil)
                    }
                }
            })
        }
    }
    
    fileprivate func observePopularUsers() {
        popularUsersRef?.removeAllObservers()
        popularUsersRef = UserService.ref.child("stories/sorted/popular/userStories")
        popularUsersRef?.queryOrderedByValue().queryLimited(toLast: 25).observeSingleEvent(of: .value, with: { snapshot in
            var stories = [(String,Int)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                let score = childSnap.value as! Int
                stories.append((key,score))
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
    
    fileprivate func observeRecentUsers() {
        recentUsersRef?.removeAllObservers()
        recentUsersRef = UserService.ref.child("stories/sorted/recent/userStories")
        recentUsersRef?.queryOrderedByValue().queryLimited(toLast: 25).observeSingleEvent(of: .value, with: { snapshot in
            var stories = [(String,Int)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                let score = childSnap.value as! Int
                stories.append((key,score))
            }
            self.downloadRecentStories(stories)
        })
    }
    
    fileprivate func downloadRecentStories(_ recent:[(String,Int)]) {
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
    
    fileprivate func observePopularPlaces() {
        popularPlacesRef?.removeAllObservers()
        popularPlacesRef = UserService.ref.child("stories/sorted/popular/places")
        popularPlacesRef?.queryOrderedByValue().queryLimited(toLast: 25).observeSingleEvent(of: .value, with: { snapshot in
            var stories = [(String,Int)]()
            for child in snapshot.children {
                let childSnap = child as! FIRDataSnapshot
                let key = childSnap.key
                let score = childSnap.value as! Int
                stories.append((key,score))
            }
            self.downloadPlacesStories(stories)
        })
    }
    
    
    
    fileprivate func downloadPlacesStories(_ popular:[(String,Int)]) {
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
    
    fileprivate func observeRecentPlaces() {
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
                        self.delegate?.update(.Popular)
                    }
                }
            })
        }
    }
    
    
}
