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
    
    var locations = [Location]()
    var locationStories = [LocationStory]()
    
    var sortMode:SortedBy = .Recent
    var userStories = [UserStory]()
    var postKeys = [String]()
    
    var storiesDictionary = [String:[String]]()
    var responseRef:FIRDatabaseReference?
    
    var gps_service:GPSService!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 4.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        
        let tabHeader = UINib(nibName: "PlacesTabHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlacesTabHeader
        tabHeader.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)
        tabHeader.refreshHandler = refreshData
        
        self.view.addSubview(tabHeader)
        
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
        
        LocationService.sharedInstance.delegate = self
        LocationService.sharedInstance.listenToResponses()
        
        locationStories = mainStore.state.nearbyPlacesActivity
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
    
    func refreshData() {
        
        /*activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator?.startAnimating()
        activityIndicator?.center = inboxButton.center
        self.view.addSubview(activityIndicator!)
        inboxButton.isHidden = true
        */
        if let lastLocation = gps_service.getLastLocation() {
            LocationService.sharedInstance.requestNearbyLocations(lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude)
        } else {
            stopRefresher()
        }
        
    }
    
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
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        mainStore.subscribe(self)
    }
    
    func newState(state: AppState) {
        locationStories = state.nearbyPlacesActivity
        locationStories.sort(by: { return $0 > $1})
        
        userStories = state.followingActivity
        userStories.sort(by: { return $0 > $1 })
        
        self.collectionView.reloadData()
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
        //activityIndicator?.stopAnimating()
        //activityIndicator?.removeFromSuperview()
        //inboxButton.isHidden = false
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


