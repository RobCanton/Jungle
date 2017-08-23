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


class HomieViewController:RoundedViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, HomeProtocol, HomeTabHeaderProtocol {
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
        
        pageScrollView = UIScrollView(frame: CGRect(x: 0, y: header.frame.height, width: view.bounds.width, height: view.bounds.height - header.frame.height - 49.0))
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
        
        state = HomeStateController(delegate:self)
        state.gps_service = gps_service
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        state.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        
    }
    
    func newState(state: AppState) {
        
    }
    
    func update(_ section:HomeSection?) {
        print("state: \(state.nearbyPosts)")
        //refreshControl.endRefreshing()
        self.collectionView.reloadData()
        self.popularCollectionView.reloadData()
        
    }
    
    func retrievingNearbyPosts(_ isRetrieving:Bool) {
        //homeHeader?.setEmptyViewLoading(isRetrieving)
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
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader && collectionView === self.collectionView {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "homeHeaderView", for: indexPath as IndexPath) as! HomeHeaderView
            homeHeader = view
            //view.delegate = self
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
        let collectionViewHeight:CGFloat = itemSize.height * 0.72
        
        var verticalHeight:CGFloat = 0
        let gpsAuthorized = gps_service.isAuthorized()
        
        verticalHeight += state.unseenFollowingStories.count > 0 || state.watchedFollowingStories.count > 0 ? bannerHeight + collectionViewHeight : 0
        verticalHeight += false ? bannerHeight + 320 : 0
        verticalHeight += state.nearbyCityStories.count > 0 ? bannerHeight + collectionViewHeight : 0
        verticalHeight += bannerHeight
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
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
            
            cell.viewMore(false)
            cell.setupCell(withPost: state.nearbyPosts[indexPath.row])
            
            return cell
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
        return indexPath.item % 6 == 0 ? TRMosaicCellType.big : TRMosaicCellType.small
    }
    
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout: TRMosaicLayoutVertical, insetAtSection:Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    func heightForSmallMosaicCell() -> CGFloat {
        return itemSize.height
    }
}
