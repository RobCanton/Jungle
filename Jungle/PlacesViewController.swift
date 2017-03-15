//
//  PlacesViewController.swift
//  Riot
//
//  Created by Robert Canton on 2017-03-14.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import View2ViewTransition

class PlacesViewController:UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, LocationDelegate {
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var collectionView:UICollectionView!
    
    var masterNav:UINavigationController?
    var container:ContainerViewController?
    var refresher:UIRefreshControl!
    
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        
        self.view.layer.cornerRadius = 6
        self.view.clipsToBounds = true
        
        itemSideLength = (UIScreen.main.bounds.width - 8.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRect(x: 1,y: 54,width: view.frame.width - 2,height: view.frame.height - 2 - 54), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "ProfileHeaderView", bundle: nil)
        
        self.collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionView.contentInset = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor(white: 0.90, alpha: 1.0)
        
        refresher = UIRefreshControl()
        collectionView.alwaysBounceVertical = true
        refresher.tintColor = UIColor.lightGray
        refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
        collectionView.addSubview(refresher)
        
        self.view.addSubview(collectionView)
        
        LocationService.sharedInstance.delegate = self
        LocationService.sharedInstance.listenToResponses()

    }
    
    func loadData()
    {
        if let lastLocation = GPSService.sharedInstance.lastLocation {
            LocationService.sharedInstance.requestNearbyLocations(lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude)
        } else {
            stopRefresher()
        }
    }
    
    func stopRefresher()
    {
        refresher.endRefreshing()
    }
    
    func locationsUpdated(locations: [Location]) {
        print("NEW LOCATIONS")
        print(locations)
        self.locations = locations
        collectionView.reloadData()
        stopRefresher()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        cell.setupLocationCell(locations[indexPath.row])
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        print("TAPPED")
        let story = locations[indexPath.item].getStory()
        if story.state == .contentLoaded {
            print("CONTENT LOADED")
            self.selectedIndexPath = indexPath
            
            let storiesViewController: StoriesViewController = StoriesViewController()
            
            
            storiesViewController.locations = self.locations
            storiesViewController.transitionController = container!.transitionController
            container!.transitionController.userInfo = ["destinationIndexPath": indexPath as AnyObject, "initialIndexPath": indexPath as AnyObject]
            
            if masterNav != nil {
                print("PUSH IT!")
                container!.returningCell = collectionView.cellForItem(at: indexPath) as! PhotoCell
                masterNav!.delegate = container!.transitionController
                container!.transitionController.push(viewController: storiesViewController, on: container!, attached: storiesViewController)
                print("PUSHED")
               // masterNav!.pushViewController(storiesViewController, animated: true)
            }
        } else {
            print("DOWNLOAD STORY")
            story.downloadStory()
            
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
}


