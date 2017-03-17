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
    
    var returningCell:PhotoCell?
    
    let transitionController: TransitionController = TransitionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        
        itemSideLength = (UIScreen.main.bounds.width - 4.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: 0,width: view.frame.width ,height: view.frame.height ), collectionViewLayout: layout)
        
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
        collectionView.backgroundColor = UIColor.white
        
        refresher = UIRefreshControl()
        collectionView.alwaysBounceVertical = true
        refresher.tintColor = UIColor.lightGray
        refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
        collectionView.addSubview(refresher)
        
        self.view.addSubview(collectionView)

        
        let segmentedControl = UISegmentedControl(items: ["Recent", "Popular", "Nearest"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.center = CGPoint(x: view.frame.width/2, y: 27 + 12)
        segmentedControl.tintColor = UIColor.darkGray
        segmentedControl.addTarget(self, action: #selector(changeSort), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
        
        LocationService.sharedInstance.delegate = self
        LocationService.sharedInstance.listenToResponses()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        globalContainerRef?.snapContainer.scrollView.isScrollEnabled = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        returningCell?.fadeInInfo(animated: true)
        returningCell = nil
        
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
            storiesViewController.transitionController = transitionController
            transitionController.userInfo = ["destinationIndexPath": indexPath as AnyObject, "initialIndexPath": indexPath as AnyObject]
            
            if let nav = self.navigationController {
                nav.delegate = transitionController
                storiesViewController.containerRef = container
                globalContainerRef?.snapContainer.scrollView.isScrollEnabled = false
                transitionController.push(viewController: storiesViewController, on: self, attached: storiesViewController)
            }
        } else {
            story.downloadStory()
            
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("COLLECTION OFFSET: \(scrollView.contentOffset.y)")
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    


}

extension PlacesViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath else {
            return CGRect.zero
        }
        
        let i =  IndexPath(row: indexPath.item, section: 0)
        let cell: PhotoCell = collectionView!.cellForItem(at: i)! as! PhotoCell
        let image_frame = cell.imageView.frame
        let x = cell.frame.origin.x + 1
        let navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        let y = cell.frame.origin.y + navHeight - collectionView!.contentOffset.y//+ navHeight
        let rect = CGRect(x: x, y: y, width: image_frame.width, height: image_frame.height)// CGRectMake(x,y,image_height, image_height)
        return view.convert(rect, to: view)
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        let cell: PhotoCell = collectionView!.cellForItem(at: i) as! PhotoCell
        print("INITIAL VIEW")
        return cell.imageView
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        print("PREP")
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        
        if !isPresenting {
            if let cell = collectionView!.cellForItem(at: indexPath) as? PhotoCell {
                returningCell?.fadeInInfo(animated: false)
                returningCell = cell
                returningCell!.fadeOutInfo()
            }
        }
        
        if !isPresenting && !collectionView!.indexPathsForVisibleItems.contains(indexPath) {
            collectionView!.reloadData()
            collectionView!.scrollToItem(at: i, at: .centeredVertically, animated: false)
            collectionView!.layoutIfNeeded()
        }
    }
    
    func dismissInteractionEnded(_ completed: Bool) {
        
//        if completed {
//            statusBarShouldHide = false
//            self.setNeedsStatusBarAppearanceUpdate()
//        }
        
    }
    
}


