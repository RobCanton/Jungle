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
    case Popular, Nearby, Recent
}

class HomeViewController:RoundedViewController, UICollectionViewDelegate, UICollectionViewDataSource, StoreSubscriber, TwicketSegmentedControlDelegate, HomeProtocol {
    var state:HomeStateController!
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var collectionView:UICollectionView!
    
    var masterNav:UINavigationController?
    var sortMode:SortedBy = .Popular
    var gps_service:GPSService!
    
    var tabHeader:PlacesTabHeader!
    
    var control:TwicketSegmentedControl!
    
    var isFollowingMode = false
    
    var topCollectionViewRef:UICollectionView?
    var midCollectionViewRef:UICollectionView?
    
    func didSelect(_ segmentIndex: Int) {
        var selectedMode:SortedBy = .Popular
        switch segmentIndex {
        case 1:
            selectedMode = .Nearby
            break
        case 2:
            selectedMode = .Recent
            break
        default:
            break
        }
        
        if selectedMode == sortMode { return }
        
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
            self.collectionView.alpha = 0.0
        }, completion: { _ in
            
            DispatchQueue.global(qos: .background).async {
                // Go back to the main thread to update the UI
                self.sortMode = selectedMode
                switch self.sortMode {
                case .Popular:
                    self.state.sortFollowingByPopularity()
                    break
                case .Nearby:
                    break
                case .Recent:
                    self.state.sortFollowingByDate()
                    break
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                        self.collectionView.alpha = 1.0
                    }, completion: { _ in
                        
                    })
                }
            }
        })
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width/3.0) - 1.0
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        tabHeader = UINib(nibName: "PlacesTabHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlacesTabHeader
        tabHeader.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 88)
        
        tabHeader.refreshHandler = refreshData
        //tabHeader.sortHandler = showSortingOptions
        
        self.view.addSubview(tabHeader)
        
        let titles = ["Popular", "Nearby", "Recent"]
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
        
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        view.addSubview(collectionView)
        
        //LocationService.sharedInstance.delegate = self

        self.collectionView.reloadData()
        
        state = HomeStateController(delegate:self)

    }
    
    
    
    func update(_ mode:SortedBy?) {
        if mode == nil || mode! == self.sortMode{
            return self.collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! FollowingHeader
            topCollectionViewRef = view.collectionViewFollowing
            midCollectionViewRef = view.collectionViewPeople
            view.setupStories(mode: sortMode, state: state)
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let bannerHeight:CGFloat = 32
        let collectionViewHeight:CGFloat = getItemSize().height * 0.677
        
        var verticalHeight:CGFloat = 0
        
        verticalHeight += bannerHeight
        
        
        if state.followingStories.count > 0 || state.myStory != nil {
            verticalHeight += collectionViewHeight + bannerHeight
        }
        
        switch sortMode {
        case .Popular:
            if state.popularUserStories.count > 0 {
                verticalHeight += collectionViewHeight + bannerHeight
            }
            break
        case .Nearby:
            if state.nearbyUserStories.count > 0 {
                verticalHeight += collectionViewHeight + bannerHeight
            }
            verticalHeight += 60
            break
        case .Recent:
            if state.recentUserStories.count > 0 {
                verticalHeight += collectionViewHeight + bannerHeight
            }
            break
        }
        return CGSize(width: collectionView.frame.size.width, height: verticalHeight)
    }

    func refreshData() {}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Home: viewWillAppear")
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    var shouldDelayLoad = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Home: viewDidAppear")
        
        if shouldDelayLoad {
            shouldDelayLoad = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.state.delegate = self
                self.collectionView.reloadData()
            }
        } else {
            mainStore.subscribe(self)
            state.delegate = self
        }
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("Home: viewDidDisappear")
        state.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("Home: viewWillDisappear")
        
    }
    
    func newState(state: AppState) {
        
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sortMode {
        case .Popular:
            return state.popularPlaceStories.count
        case .Nearby:
            return state.nearbyPlaceStories.count
        case .Recent:
            return state.recentPlaceStories.count
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        switch sortMode {
        case .Popular:
            cell.setupLocationCell(state.popularPlaceStories[indexPath.row])
            break
        case .Nearby:
            cell.setupLocationCell(state.nearbyPlaceStories[indexPath.row])
            break
        case .Recent:
            cell.setupLocationCell(state.recentPlaceStories[indexPath.row])
            break
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        
        switch sortMode {
        case .Popular:
            let story = state.popularPlaceStories[indexPath.row]
            if story.state == .contentLoaded {
                self.selectedIndexPath = indexPath
                globalMainRef?.presentPlaceStory(locationStories: state.popularPlaceStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            } else {
                story.downloadStory()
            }
            break
        case .Nearby:
            let story = state.nearbyPlaceStories[indexPath.row]
            if story.state == .contentLoaded {
                self.selectedIndexPath = indexPath
                globalMainRef?.presentPlaceStory(locationStories: state.nearbyPlaceStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            } else {
                story.downloadStory()
            }
            break
        case .Recent:
            let story = state.recentPlaceStories[indexPath.row]
            if story.state == .contentLoaded {
                self.selectedIndexPath = indexPath
                globalMainRef?.presentPlaceStory(locationStories: state.recentPlaceStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            } else {
                story.downloadStory()
            }
            break
        }
        
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    func getHeader() -> FollowingHeader? {
        print("\n\n\nINDEX PATHS")
        for x in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionElementKindSectionHeader) {
            print(x)
        }
        if let header = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? FollowingHeader {
            
            print("HEADER\n\n\n")
            return header
        }
        print("NO HEADER\n\n\n")
        return nil
    }
    
    
}


