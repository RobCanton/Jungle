//
//  PlacesViewController.swift
//  Riot
//
//  Created by Robert Canton on 2017-03-14.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import View2ViewTransition

enum SortedBy {
    case Recent,Popular,Nearest
}

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
    
    var sortMode:SortedBy = .Recent
    
    var backdrop:UIView!
    
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
        
        collectionView = UICollectionView(frame: CGRect(x: 1,y: 70,width: view.frame.width - 2,height: view.frame.height - 2 - 70), collectionViewLayout: layout)
        
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
        collectionView.backgroundColor = UIColor.clear
        
        backdrop = UIView(frame: CGRect(x: 0, y: collectionView.frame.origin.y, width: view.frame.width, height: view.frame.height - 66))
        backdrop.backgroundColor = UIColor.white
        view.insertSubview(backdrop, belowSubview: collectionView)
        
        
        
        refresher = UIRefreshControl()
        collectionView.alwaysBounceVertical = true
        refresher.tintColor = UIColor.lightGray
        refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
        collectionView.addSubview(refresher)
        
        self.view.addSubview(collectionView)
        
        
        let segmentedControl = UISegmentedControl(items: ["Recent", "Popular", "Nearest"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.center = CGPoint(x: view.frame.width/2, y: 27 + 12)
        segmentedControl.tintColor = UIColor.white
        segmentedControl.addTarget(self, action: #selector(changeSort), for: .valueChanged)
        self.view.addSubview(segmentedControl)
        
        LocationService.sharedInstance.delegate = self
        LocationService.sharedInstance.listenToResponses()

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
        
        self.locations = getSortedLocations(locations)

        collectionView.reloadData()
        stopRefresher()
    }
    
    func getSortedLocations(_ locations:[Location]) -> [Location] {
        
        switch sortMode {
        case .Recent:
            return locations.sorted(by: { $0.getStory() > $1.getStory()})
        case .Popular:
            return locations.sorted(by: { $0.getContributers().count > $1.getContributers().count})
        case .Nearest:
            return locations.sorted(by: { $0.getDistance() < $1.getDistance()})
        }
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
        let story = locations[indexPath.item].getStory()
        if story.state == .contentLoaded {
            self.selectedIndexPath = indexPath
            
            let storiesViewController: StoriesViewController = StoriesViewController()
            
            storiesViewController.locations = self.locations
            storiesViewController.transitionController = container!.transitionController
            container!.transitionController.userInfo = ["destinationIndexPath": indexPath as AnyObject, "initialIndexPath": indexPath as AnyObject]
            
            if masterNav != nil {
                masterNav!.delegate = container!.transitionController
                container!.transitionController.push(viewController: storiesViewController, on: container!, attached: storiesViewController)
            }
        } else {
            story.downloadStory()
            
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
}


