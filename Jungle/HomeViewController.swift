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
import TGPControls
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
    var sortMode:SortedBy = .Nearby
    weak var gps_service:GPSService!
    
    var tabHeader:PlacesTabHeader!
    
    var control:TwicketSegmentedControl!
    var refreshButton:UIButton!
    var refreshIndicator:UIActivityIndicatorView!
    
    var isFollowingMode = false
    
    
    var topCollectionViewRef:UICollectionView?
    var midCollectionViewRef:UICollectionView?
    
    func didSelect(_ segmentIndex: Int) {
        var selectedMode:SortedBy = .Nearby
        switch segmentIndex {
        case 1:
            selectedMode = .Popular
            break
        case 2:
            selectedMode = .Recent
            break
        default:
            break
        }
        
        if selectedMode == sortMode { return }
        
        UIView.animate(withDuration: 0.12, delay: 0.0, options: .curveEaseOut, animations: {
            self.collectionView.alpha = 0.0
        }, completion: { _ in
            
            DispatchQueue.global(qos: .background).async {
                // Go back to the main thread to update the UI
                self.sortMode = selectedMode
                switch self.sortMode {
                case .Popular:
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
    
    var sliderLabels:TGPCamelLabels!
    
    var header:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 3.0) / 3.0
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        
        tabHeader = UINib(nibName: "PlacesTabHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlacesTabHeader
        tabHeader.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 88)
        
        tabHeader.refreshHandler = refreshData
        //tabHeader.sortHandler = showSortingOptions
        
        //self.view.addSubview(tabHeader)
        
        let titles = ["Nearby", "Popular", "Following"]
        header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 88))
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tabHeader.frame.width, height: 44.0))
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightHeavy)
        titleLabel.text = "Jungle"
        titleLabel.textAlignment = .center
        header.addSubview(titleLabel)
        
        control = TwicketSegmentedControl(frame: CGRect(x: 0, y: 44, width: header.frame.width, height: 44))
        control.setSegmentItems(titles)
        control.delegate = self
        control.sliderBackgroundColor = accentColor
        header.addSubview(control)
        
        refreshButton = UIButton(frame: CGRect(x: tabHeader.frame.width - 44.0, y: 0.0, width: 44.0, height: 44.0))
        refreshButton.setImage(UIImage(named: "restart"), for: .normal)
        refreshButton.tintColor = UIColor.black
        refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        
        refreshIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        refreshIndicator.frame = refreshButton.frame
        refreshIndicator.hidesWhenStopped = true
        
        header.addSubview(refreshIndicator)
        header.addSubview(refreshButton)
        
        let clearCacheButton = UIButton(frame: CGRect(x: 0, y: 0.0, width: 44.0, height: 44.0))
        clearCacheButton.setImage(UIImage(named: "trash_2"), for: .normal)
        clearCacheButton.tintColor = UIColor.black
        clearCacheButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        header.addSubview(clearCacheButton)
        
        view.addSubview(header)
        
        var distanceLabels = [String]()
        for distance in distances {
            distanceLabels.append("\(distance) km")
        }
        
        sliderLabels = TGPCamelLabels()
        sliderLabels.frame = CGRect(x: 0, y: 52.0, width: view.frame.width, height: 36)
        sliderLabels.names = distanceLabels
        sliderLabels.upFontColor = UIColor.black
        sliderLabels.downFontColor = UIColor.clear
        sliderLabels.alpha = 0.0
        
        view.addSubview(sliderLabels)
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.5
        layout.minimumLineSpacing = 1.5
        
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
        tabHeader.startRefreshing()

    }
    
    
    func update(_ mode:SortedBy?) {
        refreshButton.isHidden = false
        refreshIndicator.stopAnimating()
        
        if mode == nil || mode! == self.sortMode{
            return self.collectionView.reloadData()
        }
    }
    
    func handleRefresh() {
        refreshButton.isHidden = true
        refreshIndicator.startAnimating()
        state.fetchAll()
    }
    
    func handleDelete() {
        clearDirectory(name: "user_content")
        print("Clear temp directory")
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! FollowingHeader
            topCollectionViewRef = view.collectionViewFollowing
            view.setupStories(mode: sortMode, state: state)
            view.sliderLabels = self.sliderLabels
            view.segmentedControl = self.control
            view.slider.ticksListener = self.sliderLabels
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let bannerHeight:CGFloat = 32
        let collectionViewHeight:CGFloat = getItemSize().height * 0.78
        
        var verticalHeight:CGFloat = 0
        
        switch sortMode {
        case .Nearby:
            verticalHeight += 48
            verticalHeight += state.nearbyPlaceStories.count > 0 ? collectionViewHeight + bannerHeight : 0
            break
        case .Popular:
            break
        case .Recent:
            break
        }
        return CGSize(width: collectionView.frame.size.width, height: verticalHeight)
    }

    func refreshData() {
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("Home: viewWillAppear")
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    var shouldDelayLoad = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //globalMainInterfaceProtocol?.fetchAllStories()
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //print("Home: viewDidDisappear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //print("Home: viewWillDisappear")
        
    }
    
    func newState(state: AppState) {
        
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sortMode {
        case .Popular:
            return state.popularPosts.count
        case .Nearby:
            return state.nearbyPosts.count
        case .Recent:
            return state.followingStories.count//recentPlaceStories.count
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        switch sortMode {
        case .Popular:
            cell.setupCell(withPost: state.popularPosts[indexPath.row])
            break
        case .Nearby:
            cell.setupCell(withPost: state.nearbyPosts[indexPath.row])
            break
        case .Recent:
            cell.setupCell(withUserStory: state.followingStories[indexPath.row])
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
            globalMainInterfaceProtocol?.presentNearbyPost(posts: state.popularPosts, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            break
        case .Nearby:
            globalMainInterfaceProtocol?.presentNearbyPost(posts: state.nearbyPosts, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            break
        case .Recent:
            let story = state.followingStories[indexPath.row]
            story.determineState()
            if story.state == .contentLoaded {
                self.selectedIndexPath = indexPath
                globalMainInterfaceProtocol?.presentUserStory(userStories: state.followingStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            } else {
                story.downloadFirstItem()
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

        if let header = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? FollowingHeader {
            
            return header
        }
        return nil
    }
    
    
}


