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
import SwiftMessages

enum SortedBy {
    case Popular, Nearby, Recent
}

enum HomeSection {
    case following, popular, places, nearby
}

class HomeViewController:RoundedViewController, UICollectionViewDelegate, UICollectionViewDataSource, StoreSubscriber, HomeProtocol {
    var state:HomeStateController!
    
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var collectionView:UICollectionView!
    
    var masterNav:UINavigationController?
    weak var gps_service:GPSService!
    
    var tabHeader:PlacesTabHeader!
    
    var refreshButton:UIButton!
    var refreshIndicator:UIActivityIndicatorView!
    
    var isFollowingMode = false
    
    var sortOptionsHidden = true
    
    var topCollectionViewRef:UICollectionView?
    var midCollectionViewRef:UICollectionView?
    
    var sliderLabels:TGPCamelLabels!
    
    var header:UIView!
    
    var messageWrapper:SwiftMessages!
    
    var followingHeader:FollowingHeader?
    var placesHeader:FollowingHeader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 3.0) / 3.0
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0))
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0))
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightHeavy)
        titleLabel.text = "Jungle"
        titleLabel.textAlignment = .center
        header.addSubview(titleLabel)
        
        refreshButton = UIButton(frame: CGRect(x: view.frame.width - 44.0, y: 0.0, width: 44.0, height: 44.0))
        refreshButton.setImage(UIImage(named: "restart"), for: .normal)
        refreshButton.tintColor = UIColor.black
        refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        
        refreshIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        refreshIndicator.frame = refreshButton.frame
        refreshIndicator.hidesWhenStopped = true
        
        header.addSubview(refreshIndicator)
        header.addSubview(refreshButton)
        
        let clearCacheButton = UIButton(frame: CGRect(x: 0, y: 0.0, width: 44.0, height: 44.0))
        clearCacheButton.setImage(UIImage(named: "sorting"), for: .normal)
        clearCacheButton.tintColor = UIColor.black
        clearCacheButton.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
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
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.5
        layout.minimumLineSpacing = 1.5
        
        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: 44.0 ,width: view.frame.width ,height: view.frame.height - 44), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "FollowingHeader", bundle: nil)
        
        self.collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        let headerNib3 = UINib(nibName: "CollectionBannerView", bundle: nil)
        
        self.collectionView.register(headerNib3, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "bannerView")
        
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeader")
     
        let headerNib2 = UINib(nibName: "CollectionDividerView", bundle: nil)
        
        self.collectionView.register(headerNib2, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "dividerView")
        
        let footerNib = UINib(nibName: "CollectionFooter", bundle: nil)
        
        self.collectionView.register(footerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footerView")
        
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 140.0, right: 0.0)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        
        view.addSubview(collectionView)
        
        //LocationService.sharedInstance.delegate = self

        self.collectionView.reloadData()
        
        refreshButton.isHidden = true
        refreshIndicator.startAnimating()
        
        state = HomeStateController(delegate:self)
        
        messageWrapper = SwiftMessages()
    }
    
    
    func update(_ section:HomeSection?) {
        refreshButton.isHidden = false
        refreshIndicator.stopAnimating()
        
        if let section = section {
            switch section {
            case .following:
                followingHeader?.setupStories(state: state, section: 0)
                break
            case .popular:
                followingHeader?.setupStories(state: state, section: 0)
                return self.collectionView.reloadData()
                
            case .places:
                placesHeader?.setupStories(state: state, section: 1)
                break
            case .nearby:
                placesHeader?.setupStories(state: state, section: 1)
                return self.collectionView.reloadData()
                
            }
        } else {
            return self.collectionView.reloadData()
        }
    }
    
    func handleRefresh() {
        uploadDataCache.removeAllObjects()
        refreshButton.isHidden = true
        refreshIndicator.startAnimating()
        state.fetchAll()
    }
    
    func handleOptions() {
        let sortOptionsView = UINib(nibName: "SortOptionsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SortOptionsView
        sortOptionsView.delegate = self
        let f = CGRect(x: 0, y: 0, width: view.frame.width, height: 190.0)
        let messageView = BaseView(frame: f)
        messageView.installContentView(sortOptionsView)
        messageView.preferredHeight = 190.0
        messageView.configureDropShadow()
        var config = SwiftMessages.defaultConfig
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .forever
        config.presentationStyle = .bottom
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = false
        messageWrapper.show(config: config, view: messageView)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            switch indexPath.section {
            case 0:
                if state.unseenFollowingStories.count == 0 && state.watchedFollowingStories.count == 0 {
                    followingHeader = nil
                    topCollectionViewRef = nil
                    if state.popularPosts.count > 0 {
                        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "bannerView", for: indexPath as IndexPath) as! CollectionBannerView
                        view.label.text = "POPULAR"
                        return view
                    }
                    return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeader", for: indexPath as IndexPath)
                } else {
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! FollowingHeader
                    followingHeader = view
                    topCollectionViewRef = view.collectionView
                    view.setupStories(state: state, section: indexPath.section)
                    return view
                }

            case 1:
                if state.nearbyPlaceStories.count == 0 {
                    placesHeader = nil
                    midCollectionViewRef = nil
                    return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeader", for: indexPath as IndexPath)
                } else {
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! FollowingHeader
                    placesHeader = view
                    midCollectionViewRef = view.collectionView
                    view.setupStories(state: state, section: indexPath.section)
                    return view
                }
            default:
                break
            }

        }
        
        
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeader", for: indexPath as IndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        
        let bannerHeight:CGFloat = 32
        let collectionViewHeight:CGFloat = getItemSize().height * 0.72
        
        var verticalHeight:CGFloat = 0
        
        switch section {
        case 0:
            verticalHeight += state.visiblePopularPosts.count > 0 ? bannerHeight: 0
            verticalHeight += state.unseenFollowingStories.count > 0 || state.watchedFollowingStories.count > 0 ? collectionViewHeight + bannerHeight : 0
            print("VerticalHeight: \(verticalHeight)")
            break
        case 1:
            ///verticalHeight += 48
            verticalHeight += state.nearbyPlaceStories.count > 0 ? collectionViewHeight + bannerHeight * 2.0 : bannerHeight
            break
        default:
            break
        }
        
        return CGSize(width: collectionView.frame.size.width, height: verticalHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeFooterInSection section: Int) -> CGSize {
        return CGSize.zero
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
        //state.observeViewed()
        state.delegate = self
        update(nil)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //print("Home: viewDidDisappear")
        //state.stopObservingViewed()
        state.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //print("Home: viewWillDisappear")
        
    }
    
    func newState(state: AppState) {
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return state.visiblePopularPosts.count
        case 1:
            return state.nearbyPosts.count
        default:
            return 0
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        
        switch indexPath.section {
        case 0:
            cell.setCrownStatus(isKing: indexPath.row == 0)
            cell.setupCell(withPost: state.visiblePopularPosts[indexPath.row])
            cell.viewMore(indexPath.row == state.visiblePopularPosts.count - 1 && state.popularPosts.count > state.visiblePopularPosts.count)
            break
        case 1:
            cell.setCrownStatus(isKing: false)
            cell.viewMore(false)
            cell.setupCell(withPost: state.nearbyPosts[indexPath.row])
            break
        default:
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
        
        let dest = IndexPath(item: indexPath.item, section: 0)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == state.visiblePopularPosts.count - 1 && state.popularPosts.count > state.visiblePopularPosts.count {
                state.popularPostsLimit += 6
                state.sortPopularPosts()
                self.collectionView.reloadSections(IndexSet(integer: 0))
            } else {
               
               globalMainInterfaceProtocol?.presentNearbyPost(posts: state.visiblePopularPosts, destinationIndexPath: dest, initialIndexPath: indexPath)
            }
            break
        case 1:
            globalMainInterfaceProtocol?.presentNearbyPost(posts: state.nearbyPosts, destinationIndexPath: dest, initialIndexPath: indexPath)
            break
        default:
            break
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.25)
    }
    
    func getHeader() -> FollowingHeader? {

        if let header = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? FollowingHeader {
            
            return header
        }
        return nil
    }
    
    
}

extension HomeViewController: SortOptionsProtocol {
    func dismissSortOptions() {
        messageWrapper.hideAll()
    }
}

