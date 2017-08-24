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
import SwiftMessages


class HomieViewController:RoundedViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, HomeProtocol, HomeTabHeaderProtocol, HomeHeaderProtocol {
    var state:HomeStateController!
    
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var collectionView:UICollectionView!
    var popularCollectionView:UICollectionView!
    
    var masterNav:UINavigationController?
    weak var gps_service:GPSService!
    
    var refreshIndicator:UIActivityIndicatorView!
    
    var isFollowingMode = false
    
    var sortOptionsHidden = true
    
    var topCollectionViewRef:UICollectionView?
    var midCollectionViewRef:UICollectionView?
    
    
    var header:HomeTabHeaderView!
    
    var messageWrapper:SwiftMessages!
    
    var followingHeader:FollowingHeader?
    var placesHeader:FollowingHeader?
    
    var refreshControl:UIRefreshControl!
    var popularRefreshControl:UIRefreshControl!
    
    var anonButton:UIButton!
    
    var homeHeader:HomeHeaderView?
    
    var shouldDelayLoad = false
    
    var pageScrollView:UIScrollView!
    var homePage:UIView!
    var popularPage:UIView!
    var itemSideLength:CGFloat = (UIScreen.main.bounds.width - 1.0) / 3.0
    var itemSize:CGSize {
        get {
            return CGSize(width: floor(itemSideLength), height: itemSideLength * 1.3)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        
        header = UINib(nibName: "HomeTabHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! HomeTabHeaderView
        
        header.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0)
        header.setup()
        header.delegate = self
        view.addSubview(header)
        
        pageScrollView = UIScrollView(frame: CGRect(x: 0, y: header.frame.height, width: view.bounds.width, height: view.bounds.height - header.frame.height))
        pageScrollView.showsHorizontalScrollIndicator = false
        pageScrollView.bounces = true
        pageScrollView.delegate = self
        pageScrollView.isPagingEnabled = true
        pageScrollView.delaysContentTouches = false
        pageScrollView.contentSize = CGSize(width: pageScrollView.bounds.width * 2.0, height: pageScrollView.bounds.height)
        
        homePage = UIView(frame: CGRect(x: 0, y: 0, width: pageScrollView.bounds.width, height: pageScrollView.bounds.height))
        homePage.backgroundColor = UIColor.red
        pageScrollView.addSubview(homePage)
        
        popularPage = UIView(frame: CGRect(x: pageScrollView.bounds.width, y: 0, width: pageScrollView.bounds.width, height: pageScrollView.bounds.height))
        popularPage.backgroundColor = UIColor.blue
        pageScrollView.addSubview(popularPage)
        
        view.addSubview(pageScrollView)
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = 0.5
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: homePage.bounds, collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let homeHeaderNib = UINib(nibName: "HomeHeaderView", bundle: nil)
        
        self.collectionView.register(homeHeaderNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "homeHeaderView")
        
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
        
        homePage.addSubview(collectionView)
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.gray
        refreshControl.backgroundColor = UIColor.clear
        
        refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
        collectionView.addSubview(self.refreshControl)
        
        //LocationService.sharedInstance.delegate = self
        
        self.collectionView.reloadData()
        refreshControl.beginRefreshing()
        
        
        let popularLayout = TRMosaicLayoutVertical()
        popularLayout.delegate = self
        popularCollectionView = UICollectionView(frame: popularPage.bounds, collectionViewLayout: popularLayout)

        popularCollectionView.register(nib, forCellWithReuseIdentifier: "popularCell")
        
        //popularCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 140.0, right: 0.0)
        
        popularCollectionView.dataSource = self
        popularCollectionView.delegate = self
        popularCollectionView.bounces = true
        popularCollectionView.isPagingEnabled = false
        popularCollectionView.showsVerticalScrollIndicator = false
        popularCollectionView.backgroundColor = UIColor.white
        
        popularPage.addSubview(popularCollectionView)
        
        popularRefreshControl = UIRefreshControl()
        popularRefreshControl.tintColor = UIColor.gray
        popularRefreshControl.backgroundColor = UIColor.clear
        
        popularRefreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
        popularCollectionView.addSubview(self.popularRefreshControl)
        
        state = HomeStateController(delegate:self)
        state.gps_service = gps_service
        
        messageWrapper = SwiftMessages()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        state.delegate = self
        update(nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        state.delegate = nil
        
    }
    
    func newState(state: AppState) {
        header.showCurrentAnonMode()
    }
    
    func update(_ section:HomeSection?) {
        print("state: \(state.nearbyPosts)")
        
        if let s = section {
            if s == .popular {
                popularRefreshControl.endRefreshing()
                self.popularCollectionView.reloadData()
            } else {
                refreshControl.endRefreshing()
                self.collectionView.reloadData()
            }
        } else {
            refreshControl.endRefreshing()
            popularRefreshControl.endRefreshing()
            self.collectionView.reloadData()
            self.popularCollectionView.reloadData()
        }

        
    }
    
    func retrievingNearbyPosts(_ isRetrieving:Bool) {
        homeHeader?.setEmptyViewLoading(isRetrieving)
    }
    
    func handleRefresh(_ sender: UIRefreshControl) {
        if sender === refreshControl {
            state.getNearby()
        } else if sender === popularRefreshControl {
            state.observePopularPosts()
        }
        
    }
    
    func modeChange(_ mode:HomeMode) {
        switch mode {
        case .home:
            pageScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            break
        case .popular:
            pageScrollView.setContentOffset(CGPoint(x: pageScrollView.bounds.width, y: 0), animated: true)
            break
        }
    }
    
    func authorizeGPS() {
        let messageView: MessageView = MessageView.viewFromNib(layout: .CenteredView)
        messageView.configureBackgroundView(width: 250)
        messageView.configureContent(title: "Enable location services", body: "Your location will be used to show you nearby posts and let you share posts with people near you.", iconImage: nil, iconText: "🌎", buttonImage: nil, buttonTitle: "Enable Location") { _ in
            self.enableLocationTapped()
            self.messageWrapper.hide()
        }
        
        let button = messageView.button!
        button.backgroundColor = accentColor
        button.titleLabel!.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightMedium)
        button.setTitleColor(UIColor.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 12.0, right: 16.0)
        button.sizeToFit()
        button.layer.cornerRadius = messageView.button!.bounds.height / 2
        button.clipsToBounds = true
        
        button.setGradient(colorA: lightAccentColor, colorB: accentColor)
        
        messageView.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
        messageView.backgroundView.layer.cornerRadius = 12
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .center
        config.duration = .forever
        config.dimMode = .blur(style: .dark, alpha: 1.0, interactive: true)
        config.presentationContext  = .window(windowLevel: UIWindowLevelStatusBar)
        self.messageWrapper.show(config: config, view: messageView)
    }
    
    func enableLocationTapped() {
        
        let status = gps_service.authorizationStatus()
        switch status {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            break
        case .denied:
            if #available(iOS 10.0, *) {
                let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)! as URL
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            } else {
                let alert = UIAlertController(title: "Go to Settings", message: "Please minimize Jungle and go to your settings to enable location services.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            break
        case .notDetermined:
            gps_service.requestAuthorization()
            break
        case .restricted:
            break
        }
    }
    
    func showSortOptions() {
        
        let status = gps_service.authorizationStatus()
        if status != .authorizedAlways && status != .authorizedWhenInUse {
            return authorizeGPS()
        }
        
        let sortOptionsView = UINib(nibName: "SortOptionsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SortOptionsView
        sortOptionsView.radiusChangedHandler = handleRadiusChange
        let f = CGRect(x: 0, y: 0, width: view.frame.width, height: 180)
        let messageView = BaseView(frame: f)
        messageView.installContentView(sortOptionsView)
        messageView.preferredHeight = 180
        messageView.configureDropShadow()
        var config = SwiftMessages.defaultConfig
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .forever
        config.presentationStyle = .bottom
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = false
        messageWrapper.show(config: config, view: messageView)
    }
    
    func handleRadiusChange(_ radius:Int) {
        LocationService.sharedInstance.setSearchRadius(radius)
        state.getNearby()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader && collectionView === self.collectionView {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "homeHeaderView", for: indexPath as IndexPath) as! HomeHeaderView
            homeHeader = view
            view.delegate = self
            view.setup(_state: state, isLocationEnabled: gps_service.isAuthorized())
            return view
        }
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeader", for: indexPath as IndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if collectionView === popularCollectionView {
            return CGSize.zero
        }
        let bannerHeight:CGFloat = 32
        let collectionViewHeight:CGFloat = itemSize.height * 0.74
        
        var verticalHeight:CGFloat = 0
        let gpsAuthorized = gps_service.isAuthorized()

        verticalHeight += state.hasHeaderPosts ? collectionViewHeight + bannerHeight + 16.0: 0
        verticalHeight += !gpsAuthorized ? 140 : 0
        verticalHeight += state.nearbyPosts.count == 0 && gpsAuthorized ? 130 : 0
        
        return CGSize(width: collectionView.frame.size.width, height: verticalHeight)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case self.collectionView:
            return gps_service.isAuthorized() ? state.nearbyPosts.count : 0
        case popularCollectionView:
            return state.popularPosts.count
        default:
            return 0
        }

        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === popularCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "popularCell", for: indexPath as IndexPath) as! PhotoCell
            
            cell.viewMore(false)
            cell.setupCell(withPost: state.popularPosts[indexPath.row])
            cell.setCrownStatus(index: indexPath.item)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
            
            cell.viewMore(false)
            cell.setupCell(withPost: state.nearbyPosts[indexPath.row])
            
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === self.collectionView {
            let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
            
            let dest = IndexPath(item: indexPath.item, section: 0)
            
            globalMainInterfaceProtocol?.presentNearbyPost(presentationType: .homeCollection, posts: state.nearbyPosts, destinationIndexPath: dest, initialIndexPath: indexPath)
            
            collectionView.deselectItem(at: indexPath, animated: true)
        } else if collectionView === self.popularCollectionView {
            let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "popularCell", for: indexPath) as! PhotoCell
            
            let dest = IndexPath(item: indexPath.item, section: 0)
            
            globalMainInterfaceProtocol?.presentNearbyPost(presentationType: .popular, posts: state.popularPosts, destinationIndexPath: dest, initialIndexPath: indexPath)
            
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return itemSize
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === pageScrollView {
            let xOffset = scrollView.contentOffset.x
            let progress = xOffset / scrollView.frame.width
            header.setSliderPos(progress)
        }
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === pageScrollView {
            let xOffset = scrollView.contentOffset.x
            header.setState(xOffset < scrollView.frame.width ? .home : .popular)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }

}

extension HomieViewController: TRMosaicLayoutVerticalDelegate {
    
    func collectionView(_ collectionView:UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath:IndexPath) -> TRMosaicCellType {
        // I recommend setting every third cell as .Big to get the best layout
        return indexPath.item % 3 == 0 ? TRMosaicCellType.big : TRMosaicCellType.small
    }
    
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout: TRMosaicLayoutVertical, insetAtSection:Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    func heightForSmallMosaicCell() -> CGFloat {
        return itemSize.height
    }
}
