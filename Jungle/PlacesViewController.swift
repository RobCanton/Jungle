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

enum SortedBy {
    case Recent,Popular,Nearest
}

class PlacesViewController:RoundedViewController, UICollectionViewDelegate, UICollectionViewDataSource, LocationDelegate, StoreSubscriber {
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var collectionView:UICollectionView!
    
    var masterNav:UINavigationController?
    var refresher:UIRefreshControl!
    
    var locations = [Location]()
    var locationStories = [LocationStory]()
    
    var sortMode:SortedBy = .Recent
    var userStories = [UserStory]()
    var postKeys = [String]()
    
    var storiesDictionary = [String:[String]]()
    var responseRef:FIRDatabaseReference?
    
    var inboxButton:UIButton!
    
    var gps_service:GPSService!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 4.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: 44,width: view.frame.width ,height: view.frame.height - 44), collectionViewLayout: layout)
        
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
        
        let segmentedControl = UISegmentedControl(items: ["Recent", "Popular", "Nearest"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.center = CGPoint(x: view.frame.width/2, y: 22)
        segmentedControl.tintColor = UIColor.darkGray
        segmentedControl.addTarget(self, action: #selector(changeSort), for: .valueChanged)
        //view.addSubview(segmentedControl)
        //self.navigationItem.titleView = segmentedControl
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width - 96, height: 44))
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightHeavy)
        label.text = "Jungle"
        label.textAlignment = .center
        label.center = CGPoint(x: view.frame.width/2, y: 22)
        view.addSubview(label)
        
        inboxButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        inboxButton.setImage(UIImage(named:"restart"), for: .normal)
        inboxButton.center = CGPoint(x: view.frame.width - 20 - 8, y: 22)
        inboxButton.addTarget(self, action: #selector(refreshData), for: .touchUpInside)
        inboxButton.tintColor = UIColor.darkGray
        view.addSubview(inboxButton)
        
        LocationService.sharedInstance.delegate = self
        LocationService.sharedInstance.listenToResponses()
        self.collectionView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! FollowingHeader
            view.setupStories(_userStories: userStories)
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if userStories.count == 0 {
            return CGSize.zero
        }
        return CGSize(width: collectionView.frame.size.width, height: 90)
    }
    
    var activityIndicator:UIActivityIndicatorView?
    
    func refreshData() {
        
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator?.startAnimating()
        activityIndicator?.center = inboxButton.center
        self.view.addSubview(activityIndicator!)
        inboxButton.isHidden = true
        
        if let lastLocation = gps_service.getLastLocation() {
            LocationService.sharedInstance.requestNearbyLocations(lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude)
        } else {
            stopRefresher()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    func requestActivity() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("api/requests/story/\(uid)")
        ref.setValue(true)
    }
    
    func listenToActivityResponse() {
        let uid = mainStore.state.userState.uid
        responseRef = UserService.ref.child("api/responses/story/\(uid)")
        responseRef?.removeAllObservers()
        responseRef?.observe(.value, with: { snapshot in
            var tempStories = [UserStory]()
            if snapshot.exists() {
                
                for user in snapshot.children {
                    
                    let userSnap = user as! FIRDataSnapshot

                    if let _postKeys = userSnap.value as? [String:Double] {
                        let story = UserStory(postKeys: _postKeys.valueKeySorted, uid: userSnap.key)
                        tempStories.append(story)
                    }
                }
                
                self.crossCheckStories(tempStories: tempStories)
                self.responseRef?.removeValue()
            }
        })
    }
    
    func crossCheckStories(tempStories:[UserStory]) {

        var mutableStories = tempStories
        var myStory:UserStory?
        
        for i in 0..<tempStories.count {
            let story = tempStories[i]
            
            if story.getUserId() == mainStore.state.userState.uid {
                myStory = story
                mutableStories.remove(at: i)
            }
        }
        
        if myStory != nil {
            mutableStories.insert(myStory!, at: 0)
        }
        
        self.userStories = mutableStories
        self.collectionView.reloadData()
        //getHeader()?.setupStories(_userStories: self.userStories)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestActivity()
        listenToActivityResponse()
        
    }
    
    func newState(state: AppState) {

    }
    
    func changeSort(control: UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0:
            sortMode = .Recent
            break
        case 1:
            sortMode = .Popular
            break
        case 2:
            sortMode = .Nearest
            break
        default:
            break
        }
        
        DispatchQueue.global(qos: .background).async {
            
            
            self.locations = self.getSortedLocations(self.locations)
            
            // Go back to the main thread to update the UI
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                
            }
        }

        
    }
    
    func stopRefresher()
    {
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        inboxButton.isHidden = false
    }
    
    func locationsUpdated(locations: [Location]) {
        
        //self.locations = getSortedLocations(locations)
        
        var tempStories = [LocationStory]()
        
        var count = 0
        for i in 0..<locations.count {
            let location = locations[i]
            
            LocationService.sharedInstance.getLocationStory(location.getKey(), completon: { story in
                if story != nil {
                    tempStories.append(story!)
                }
                count += 1
                if count >= locations.count {
                    count = -1
                    self.locationStories = tempStories.sorted(by: {$0 > $1})
                    self.collectionView.reloadData()
                    self.stopRefresher()
                }
            })
        }
    }
    
    func getSortedLocations(_ locations:[Location]) -> [Location] {
        
        /*switch sortMode {
        case .Recent:
            return locations.sorted(by: { $0.getStory() > $1.getStory()})
        case .Popular:
            return locations.sorted(by: { $0.getContributers().count > $1.getContributers().count})
        case .Nearest:
            return locations.sorted(by: { $0.getDistance() < $1.getDistance()})
        }*/
        return locations
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    func getHeader() -> FollowingHeader? {
        return collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? FollowingHeader
    }
    
}


