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

enum SortedBy {
    case Popular, Nearby, Recent
}

enum HomeSection {
    case following, popular, places, nearby
}

class HomeViewController:RoundedViewController, UICollectionViewDelegate, UICollectionViewDataSource, StoreSubscriber, HomeProtocol, HomeHeaderProtocol {
    var state:HomeStateController!
    
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var collectionView:UICollectionView!
    
    var masterNav:UINavigationController?
    weak var gps_service:GPSService!
    
    var refreshIndicator:UIActivityIndicatorView!
    
    var isFollowingMode = false
    
    var sortOptionsHidden = true
    
    var topCollectionViewRef:UICollectionView?
    var midCollectionViewRef:UICollectionView?
    
    
    var header:UIView!
    
    var messageWrapper:SwiftMessages!
    
    var followingHeader:FollowingHeader?
    var placesHeader:FollowingHeader?
    
    var refreshControl:UIRefreshControl!
    
    var anonButton:UIButton!
    
    var homeHeader:HomeHeaderView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 1.0) / 3.0
        self.automaticallyAdjustsScrollViewInsets = true
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0))
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0))
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightHeavy)
        titleLabel.text = "Jungle"
        titleLabel.textAlignment = .center
        header.addSubview(titleLabel)
        
        let bar = UIView(frame: CGRect(x: 0, y: header.bounds.height - 1, width: header.bounds.width, height: 1.0))
        bar.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        
        
        let optionsButton = UIButton(frame: CGRect(x: view.frame.width - 44.0, y: 0.0, width: 44.0, height: 44.0))
        optionsButton.setImage(UIImage(named: "sorting"), for: .normal)
        optionsButton.tintColor = UIColor.black
        optionsButton.addTarget(self, action: #selector(showSortOptions), for: .touchUpInside)
        header.addSubview(optionsButton)
        
        view.addSubview(header)
        

        anonButton = UIButton(frame: CGRect(x: 6.0, y: 6.0, width: 32.0, height: 32.0))
        anonButton.setImage(UIImage(named: "private2"), for: .normal)
        anonButton.layer.cornerRadius = anonButton.frame.height / 2
        anonButton.clipsToBounds = true
        anonButton.backgroundColor = accentColor
        anonButton.addTarget(self, action: #selector(switchAnonMode), for: .touchUpInside)
        
        header.addSubview(anonButton)
        showCurrentAnonMode()
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 0.5
        layout.minimumLineSpacing = 1.0
        

        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: 44.0 ,width: view.frame.width ,height: view.frame.height - 44), collectionViewLayout: layout)
        
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
        
        view.addSubview(collectionView)
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.gray
        refreshControl.backgroundColor = UIColor.clear
        
        refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
        collectionView.addSubview(self.refreshControl)
        
        //LocationService.sharedInstance.delegate = self

        self.collectionView.reloadData()
        refreshControl.beginRefreshing()
        
        state = HomeStateController(delegate:self)
        state.gps_service = gps_service
        
        messageWrapper = SwiftMessages()
    }
    
    func switchAnonMode() {
        
        mainStore.dispatch(ToggleAnonMode())
        if userState.anonMode {
            Alerts.showStatusAnonAlert(inWrapper: messageWrapper)
        } else {
            Alerts.showStatusPublicAlert(inWrapper: messageWrapper)
        }
    }
    
    func showCurrentAnonMode() {
        let isAnon = mainStore.state.userState.anonMode
        if isAnon {
            
            anonButton.setImage(UIImage(named:"private2"), for: .normal)
            anonButton.backgroundColor = accentColor

            
        } else {
            guard let user = mainStore.state.userState.user else {
                return
            }
            anonButton.setImage(nil, for: .normal)
            loadImageCheckingCache(withUrl: user.imageURL, check: 0, completion: { image, fromFile, check in
                if image != nil && !userState.anonMode{
                    self.anonButton.setImage(image!, for: .normal)
                }
            })

            anonButton.backgroundColor = infoColor

            
        }
    }
    
    
    func update(_ section:HomeSection?) {
        refreshControl.endRefreshing()
        return self.collectionView.reloadData()

    }
    
    func retrievingNearbyPosts(_ isRetrieving:Bool) {
        homeHeader?.setEmptyViewLoading(isRetrieving)
    }
    
    func handleRefresh() {
        state.fetchAll()
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
            authorizeGPS()
            return
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
        //LocationService.sharedInstance.setSearchRadius(radius)
        state.getNearby()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "homeHeaderView", for: indexPath as IndexPath) as! HomeHeaderView
            homeHeader = view
            view.delegate = self
            view.setup(_state: state, isLocationEnabled: gps_service.isAuthorized())
            return view
        }
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeader", for: indexPath as IndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let bannerHeight:CGFloat = 32
        let collectionViewHeight:CGFloat = getItemSize().height * 0.72
        
        var verticalHeight:CGFloat = 0
        let gpsAuthorized = gps_service.isAuthorized()
        
        verticalHeight += state.unseenFollowingStories.count > 0 || state.watchedFollowingStories.count > 0 ? bannerHeight + collectionViewHeight : 0
        verticalHeight += true ? bannerHeight + 320 : 0
        verticalHeight += state.nearbyCityStories.count > 0 ? bannerHeight + collectionViewHeight : 0
        verticalHeight += bannerHeight
        verticalHeight += !gpsAuthorized ? 140 : 0
        verticalHeight += state.nearbyPosts.count == 0 && gpsAuthorized ? 130 : 0
        
        return CGSize(width: collectionView.frame.size.width, height: verticalHeight)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func refreshData() {
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    var shouldDelayLoad = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        state.delegate = self
        update(nil)
        
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
        showCurrentAnonMode()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return gps_service.isAuthorized() ? state.nearbyPosts.count : 0
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        
        cell.viewMore(false)
        cell.setupCell(withPost: state.nearbyPosts[indexPath.row])

        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        
        let dest = IndexPath(item: indexPath.item, section: 0)
        
        globalMainInterfaceProtocol?.presentNearbyPost(presentationType: .homeCollection, posts: state.nearbyPosts, destinationIndexPath: dest, initialIndexPath: indexPath)

        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: floor(itemSideLength), height: itemSideLength * 1.3)
    }
    
    func getHeader() -> FollowingHeader? {

        if let header = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? FollowingHeader {
            
            return header
        }
        return nil
    }
    
}


extension HomeViewController: TRMosaicLayoutVerticalDelegate {
    
    func collectionView(_ collectionView:UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath:IndexPath) -> TRMosaicCellType {
        // I recommend setting every third cell as .Big to get the best layout
        return TRMosaicCellType.small
    }
    
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout: TRMosaicLayoutVertical, insetAtSection:Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    func heightForSmallMosaicCell() -> CGFloat {
        return (view.bounds.width / 3) * 1.3
    }
}
