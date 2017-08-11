//
//  HomeStateController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import ReSwift

protocol HomeProtocol: class {
    func update(_ section: HomeSection?)
}

class HomeStateController: StoreSubscriber {
    weak var delegate:HomeProtocol?
    
    private(set) var myStory:UserStory?
    
    var popularPostsLimit = 6
    
    private(set) var nearbyPosts = [StoryItem]()
    private(set) var popularPosts = [StoryItem]()
    private(set) var visiblePopularPosts = [StoryItem]()
    
    fileprivate var nearbyRef:DatabaseReference?
    fileprivate var popularRef:DatabaseReference?
    
    private(set) var followingStories = [UserStory]()
    private(set) var unseenFollowingStories = [UserStory]()
    private(set) var watchedFollowingStories = [UserStory]()
    
    private(set) var nearbyFollowingStories = [UserStory]()
    private(set) var popularUserStories = [UserStory]()
    private(set) var nearbyUserStories = [UserStory]()
    private(set) var recentUserStories = [UserStory]()
    
    private(set) var popularPlaceStories = [LocationStory]()
    private(set) var recentPlaceStories = [LocationStory]()
    private(set) var nearbyPlaceStories = [LocationStory]()
    
    private(set) var nearbyCityStories = [CityStory]()
    
    fileprivate var myStoryRef:DatabaseReference?
    fileprivate var followingRef:DatabaseReference?
    fileprivate var nearbyFollowingRef:DatabaseReference?
    fileprivate var popularUsersRef:DatabaseReference?
    fileprivate var nearbyUsersRef:DatabaseReference?
    fileprivate var recentUsersRef:DatabaseReference?
    
    fileprivate var popularPlacesRef:DatabaseReference?
    fileprivate var nearbyPlacesRef:DatabaseReference?
    fileprivate var nearbyCitiesRef:DatabaseReference?
    fileprivate var recentPlacesRef:DatabaseReference?
    
    private(set) var viewedPosts = [String:Double]()
    
    init(delegate:HomeProtocol)
    {
        self.delegate = delegate
        
        fetchAll()
    }
    
    func newState(state: AppState) {
        downloadFollowingStories()
    }
    
    func clear() {
        
        myStory = nil
        UserService.stopObservingUserStory(mainStore.state.userState.uid)
        popularPosts = [StoryItem]()
        visiblePopularPosts = [StoryItem]()
        
        followingStories = [UserStory]()
        nearbyFollowingStories = [UserStory]()
        popularUserStories = [UserStory]()
        nearbyUserStories = [UserStory]()
        recentUserStories = [UserStory]()
        
        popularPlaceStories = [LocationStory]()
        recentPlaceStories = [LocationStory]()
        nearbyPlaceStories = [LocationStory]()
        
        myStoryRef?.removeAllObservers()
        nearbyFollowingRef?.removeAllObservers()
        popularUsersRef?.removeAllObservers()
        recentUsersRef?.removeAllObservers()
        popularPlacesRef?.removeAllObservers()
        nearbyPlacesRef?.removeAllObservers()
        recentPlacesRef?.removeAllObservers()
        
        nearbyCitiesRef?.removeAllObservers()
        
        myStoryRef = nil
        followingRef = nil
        nearbyFollowingRef = nil
        popularUsersRef = nil
        recentUsersRef = nil
        popularPlacesRef = nil
        nearbyPlacesRef = nil
        recentPlacesRef = nil
        
        nearbyCitiesRef = nil
        stopObservingViewed()
        viewedPosts = [:]
        
    }
    
    func fetchAll() {
        mainStore.subscribe(self)
        observeMyStory()
        observeNearbyCities()
        //observeNearbyPlaces()
        observeNearbyPosts()
        observePopularPosts()
        observeViewed()
    }
    
    func observeViewed() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("users/viewed/\(uid)")
        
        let now = Date()
        let tempCalendar = Calendar.current
        let alteredDate = tempCalendar.date(byAdding: .day, value: -1, to: now)!
        let oneDayAgoTimestamp = alteredDate.timeIntervalSince1970 * 1000
        
        ref.queryOrderedByValue().queryStarting(atValue: oneDayAgoTimestamp).observe(.childAdded, with: { snapshot in
            self.viewedPosts[snapshot.key] = snapshot.value as! Double
            self.sortFollowingStories()
        })
        
    }
    
    func stopObservingViewed() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("users/viewed/\(uid)")
        ref.removeAllObservers()
    }
    
    func hasViewedStory(_ story: Story) -> Bool {
        for post in story.posts {
            if viewedPosts[post] == nil {
                return false
            }
        }
        return true
    }
    
    
    fileprivate func observeMyStory() {
        UserService.observeUserStory(mainStore.state.userState.uid) { story in
            self.myStory = story
            self.sortFollowingStories()
        }
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
    
    
    fileprivate func downloadFollowingStories() {
        var stories = [UserStory]()
        var following = mainStore.state.socialState.following.sorted()
        
        var count = 0
        for uid in following {
            
            
            UserService.getUserStory(uid, completion: { story in
                if story != nil {
                    stories.append(story!)
                }
                count += 1
                if count >= following.count {
                    count = -1
                    
                    self.followingStories = stories
                    self.sortFollowingStories()
                   // DispatchQueue.main.async {
                        //self.delegate?.update(.following)
                    //}
                }
            })
        }
    }
    
    
    func sortFollowingStories() {
        var unseenStories = [UserStory]()
        var watchedStories = [UserStory]()
        
        for story in followingStories {
            if story.hasViewed() {
                watchedStories.append(story)
            } else {
                unseenStories.append(story)
            }
        }
        
        self.unseenFollowingStories = unseenStories.sorted(by: { return $0 > $1 })
        self.watchedFollowingStories = watchedStories.sorted(by: { return $0 > $1 })
        
        if myStory != nil {
            self.unseenFollowingStories.insert(myStory!, at: 0)
        }
        
        DispatchQueue.main.async {
            self.delegate?.update(.following)
        }
    }
    
    
    fileprivate func observeNearbyPosts() {
        let uid = mainStore.state.userState.uid
        nearbyRef?.removeAllObservers()
        nearbyRef = UserService.ref.child("users/location/nearby/\(uid)/posts")
        nearbyRef?.queryOrdered(byChild: "t").queryLimited(toLast: 150).observe(.value, with: { snapshot in
            
            var posts = [String]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                let key = childSnap.key
                posts.append(key)
            }
            
            self.downloadPosts(posts)
        })
    }
    
    fileprivate func downloadPosts(_ posts:[String]) {
        var nearbyPosts = [StoryItem]()
        if posts.count == 0 {
            self.nearbyPosts = nearbyPosts
            delegate?.update(.nearby)
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
                    //DispatchQueue.main.async {
                        self.delegate?.update(.nearby)
                    //}
                }
                
            })
        }
    }
    
    fileprivate func observeNearbyCities() {
        let uid = mainStore.state.userState.uid
        nearbyCitiesRef?.removeAllObservers()
        nearbyCitiesRef = UserService.ref.child("users/location/nearby/\(uid)/cities")
        nearbyCitiesRef?.queryOrderedByValue().observe(.value, with: { snapshot in
            var cities = [String:Double]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                let key = childSnap.key
                if let distance = childSnap.value as? Double {
                    cities[key] = distance
                }
            }
            self.downloadNearbyCityStories(cities)
        })
    }
    
    fileprivate func downloadNearbyCityStories(_ cities:[String:Double]) {
        var cityStories = [CityStory]()
        if cities.count == 0 {
            self.nearbyCityStories = cityStories
            delegate?.update(.places)
            return
        }
        var count = 0
        for (key, distance) in cities {
            LocationService.sharedInstance.getCityStory(key, withDistance: distance) { story in
                if story != nil {
                    cityStories.append(story!)
                }
                count += 1
                if count >= cities.count {
                    count = -1
                    self.nearbyCityStories = cityStories.sorted(by: { return $0.distance < $1.distance })
                    
                    // DispatchQueue.main.async {
                    self.delegate?.update(.places)
                    // }
                }
            }
        }
    }
    
    fileprivate func observeNearbyPlaces() {
        let uid = mainStore.state.userState.uid
        nearbyPlacesRef?.removeAllObservers()
        nearbyPlacesRef = UserService.ref.child("users/location/nearby/\(uid)/places")
        nearbyPlacesRef?.queryOrderedByValue().observe(.value, with: { snapshot in
            var places = [String:Double]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                let key = childSnap.key
                if let distance = childSnap.value as? Double {
                    places[key] = distance
                }
            }
            self.downloadNearbyPlacesStories(places)
        })
    }
    
    fileprivate func downloadNearbyPlacesStories(_ places:[String:Double]) {
        var placesStories = [LocationStory]()
        if places.count == 0 {
            self.nearbyPlaceStories = placesStories
            delegate?.update(.places)
            return
        }
        var count = 0
        for (key, distance) in places {
            LocationService.sharedInstance.getLocationStory(key, withDistance: distance) { story in
                if story != nil {
                    placesStories.append(story!)
                }
                count += 1
                if count >= places.count {
                    count = -1
                    self.nearbyPlaceStories = placesStories.sorted(by: { return $0.count > $1.count })
                    
                   // DispatchQueue.main.async {
                        self.delegate?.update(.places)
                   // }
                }
            }
        }
    }
    
    fileprivate func observePopularPosts() {
        popularRef?.removeAllObservers()
        popularRef = UserService.ref.child("uploads/popular/")
        popularRef?.queryOrderedByValue().queryLimited(toLast: 25).observe(.value, with: { snapshot in
            var posts = [String:Double]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                let key = childSnap.key
                if let d = childSnap.value as? Double {
                    posts[key] = d
                }
            }
        
            self.downloadPopularPosts(posts)
        })
    }
    
    fileprivate func downloadPopularPosts(_ posts:[String:Double]) {
        var popularPosts = [StoryItem]()
        
        if posts.count == 0 {
            self.popularPosts = popularPosts
            self.sortPopularPosts()
            return
        }
        
        var count = 0
        for (key, _) in posts {
            UploadService.getUpload(key: key, completion: { item in
                if item != nil {
                    popularPosts.append(item!)
                }
                
                count += 1
                if count >= posts.count {
                    count = -1
                    
                    self.popularPosts = popularPosts.sorted(by: { return $0.popularity > $1.popularity })
                   self.sortPopularPosts()
                }
                
            })
        }
    }
    
    func sortPopularPosts() {
        
        let numVisiblePosts = min(popularPostsLimit, self.popularPosts.count)
        var tempPosts = [StoryItem]()
        for i in 0..<numVisiblePosts {
            tempPosts.append(popularPosts[i])
        }
        
        self.visiblePopularPosts = tempPosts
        self.delegate?.update(.popular)
    }
}
