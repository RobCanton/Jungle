//
//  PlacesViewController.swift
//  Riot
//
//  Created by Robert Canton on 2017-03-14.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import View2ViewTransition
import Firebase
import ReSwift
import MapKit
import TwicketSegmentedControl

enum SortedBy {
    case Recent,Nearest,Following
}

class PlacesViewController:RoundedViewController, UICollectionViewDelegate, UICollectionViewDataSource, LocationDelegate, StoreSubscriber, TwicketSegmentedControlDelegate {
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var collectionView:UICollectionView!
    
    var masterNav:UINavigationController?
    
    var locations = [Location]()
    var locationStories = [LocationStory]()
    
    var sortMode:SortedBy = .Recent
    var myStory:UserStory?
    var userStories = [UserStory]()
    var postKeys = [String]()
    
    var storiesDictionary = [String:[String]]()
    var responseRef:FIRDatabaseReference?
    
    var gps_service:GPSService!
    
    var tabHeader:PlacesTabHeader!
    var sortOptionsView:SortOptionsView!
    
    var control:TwicketSegmentedControl!
    
    var isFollowingMode = false
    
    func didSelect(_ segmentIndex: Int) {
        
        if segmentIndex == 0 {
            sortMode = .Recent
            locationStories.sort(by: { return $0 > $1})
        } else if segmentIndex == 1 {
            sortMode = .Nearest
            locationStories.sort(by: { return $0.getDistance() < $1.getDistance()})
        } else if segmentIndex == 2 {
            sortMode = .Following
            locationStories.sort(by: { return $0.getPosts().count > $1.getPosts().count})
        }
        
        DispatchQueue.global(qos: .background).async {
            // Go back to the main thread to update the UI
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 4.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        tabHeader = UINib(nibName: "PlacesTabHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlacesTabHeader
        tabHeader.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 88)
        
        tabHeader.refreshHandler = refreshData
        tabHeader.sortHandler = showSortingOptions
        
        sortOptionsView = UINib(nibName: "SortOptionsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SortOptionsView
        sortOptionsView.frame = CGRect(x: 0, y: 44, width: view.frame.width, height: 160)
        sortOptionsView.alpha = 0.0
        sortOptionsView.setNeedsLayout()
        sortOptionsView.layoutIfNeeded()
        sortOptionsView.layoutSubviews()
        sortOptionsView.setNeedsUpdateConstraints()
        sortOptionsView.updateConstraints()

        
        self.view.addSubview(tabHeader)
        self.view.addSubview(sortOptionsView)
        
        let titles = ["Recent", "Nearby", "Popular"]
        let frame = CGRect(x: 0, y: 44.0, width: view.frame.width, height: 44)
        
        control = TwicketSegmentedControl(frame: frame)
        control.setSegmentItems(titles)
        control.delegate = self
        control.sliderBackgroundColor = accentColor
        
        view.addSubview(control)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: 88.0 ,width: view.frame.width ,height: view.frame.height - 44), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "FollowingHeader", bundle: nil)
        
        self.collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionView.contentInset = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        view.addSubview(collectionView)
        
        LocationService.sharedInstance.delegate = self
        
        locationStories = mainStore.state.nearbyPlacesActivity
        self.collectionView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! FollowingHeader
            view.setupStories(_userStories: userStories, myStory: myStory)
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if userStories.count == 0 && myStory == nil {
            return CGSize.zero
        }
        return CGSize(width: collectionView.frame.size.width, height: getItemSize().height * 0.75 + 12)
    }

    func refreshData() {}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    var shouldDelayLoad = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        
        if shouldDelayLoad {
            shouldDelayLoad = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                mainStore.subscribe(self)
            }
        } else {
            mainStore.subscribe(self)
        }
        
        
    }
    
    func newState(state: AppState) {
        
        let posts = state.myActivity
        myStory = posts.count > 0 ? UserStory(postKeys: posts, uid: state.userState.uid) : nil
        
        locationStories = state.nearbyPlacesActivity
        locationStories.sort(by: { return $0 > $1})
        
        if sortMode == .Recent{
            locationStories.sort(by: { return $0 > $1})
        } else if sortMode == .Nearest {
            locationStories.sort(by: { return $0.getDistance() < $1.getDistance()})
        }
        
        let following = state.followingActivity
        
        var new = [UserStory]()
        var viewed = [UserStory]()
        for story in following {
            if story.hasViewed() {
                viewed.append(story)
            } else {
                new.append(story)
            }
        }
        
        new.sort(by: { return $0 > $1 })
        viewed.sort(by: { return $0 > $1 })
        
        new.append(contentsOf: viewed)
        userStories = new
        
        self.collectionView.reloadData()
    }
    
    
    func stopRefresher()
    {
    }
    
    func locationsUpdated(locations: [Location]) {
    }
    
    var sortOptionsHidden = true
    
    func showSortingOptions() {
        if sortOptionsHidden {
            sortOptionsHidden = false
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                
                var controlFrame = self.control.frame
                controlFrame.origin.y = 44.0 + self.sortOptionsView.frame.height
                self.control.frame = controlFrame
                
                var collectionFrame = self.collectionView.frame
                collectionFrame.origin.y = 88.0 + self.sortOptionsView.frame.height
                self.collectionView.frame = collectionFrame
                
                self.sortOptionsView.alpha =  1.0
                
            }, completion: { _ in })
        } else {
            sortOptionsHidden = true
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                var controlFrame = self.control.frame
                controlFrame.origin.y = 44.0
                self.control.frame = controlFrame
                
                var collectionFrame = self.collectionView.frame
                collectionFrame.origin.y = 88.0
                self.collectionView.frame = collectionFrame
                self.sortOptionsView.alpha =  0.0
            
            }, completion: { _ in })
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locationStories.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        cell.setupLocationCell(locationStories[indexPath.row])
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        let story = locationStories[indexPath.item]
        if story.state == .contentLoaded {
            self.selectedIndexPath = indexPath
            globalMainRef?.presentPlaceStory(locationStories: self.locationStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
        } else {
            story.downloadStory()
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    func getHeader() -> FollowingHeader? {
        return collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? FollowingHeader
    }
    
    
}


