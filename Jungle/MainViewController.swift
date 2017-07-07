//
//  MainViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-19.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import View2ViewTransition
import GoogleMaps
import GooglePlaces
import ReSwift
import JSQMessagesViewController
import SwiftMessages

var globalMainInterfaceProtocol:MainInterfaceProtocol?

protocol MainInterfaceProtocol {
    func setScrollState(_ enabled:Bool)
    func navigationPush(withController controller: UIViewController, animated: Bool)
    func presentPopover(withController controller: UIViewController, animated: Bool)
    func presentHomeScreen(animated: Bool)
    func presentCamera()
    func fetchAllStories()
    func statusBar(hide: Bool, animated:Bool)
    func presentNearbyPost(posts:[StoryItem], destinationIndexPath:IndexPath, initialIndexPath:IndexPath)
    func presentBannerStory(presentationType:PresentationType, stories:[Story], destinationIndexPath:IndexPath, initialIndexPath:IndexPath )
    func presentUserStory(userStories:[UserStory], destinationIndexPath:IndexPath, initialIndexPath:IndexPath)
    func presentProfileStory(posts:[StoryItem], destinationIndexPath:IndexPath, initialIndexPath:IndexPath)
    func presentNotificationPost(post:StoryItem, destinationIndexPath:IndexPath, initialIndexPath:IndexPath)
}

extension MainViewController: MainInterfaceProtocol {
    
    func setScrollState(_ enabled: Bool) {
        self.scrollView.isScrollEnabled = enabled
    }
    
    func navigationPush(withController controller: UIViewController, animated: Bool) {
        navigationController?.delegate = nil
        activateNavbar(true)
        navigationController?.pushViewController(controller, animated: animated)
    }
    
    func presentPopover(withController controller: UIViewController, animated: Bool) {
        self.present(controller, animated: animated, completion: nil)
    }
    
    func presentHomeScreen(animated: Bool) {
        cameraView.cameraState = .Initiating
        scrollView.setContentOffset(CGPoint(x: 0, y: view.frame.height * 2.0), animated: animated)
        mainTabBar.selectedIndex = 0
        
    }
    
    func presentCamera() {
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.frame.height), animated: true)
    }
    
    func fetchAllStories() {
        places.state.fetchAll()
        LocationService.sharedInstance.requestNearbyLocations()
        
    }
}

class MainViewController: UIViewController, StoreSubscriber, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    fileprivate var gps_service:GPSService!
    fileprivate var message_service:MessageService!
    fileprivate var notification_service:NotificationService!
    
    fileprivate var scrollView:UIScrollView!
    
    fileprivate var cameraView:CameraViewController!
    fileprivate var recordBtn:CameraButton!
    fileprivate var recordBtnDummy:CameraButton!
    fileprivate var cameraBtnFrame:CGRect!
    fileprivate var cameraCenter:CGPoint!
    
    fileprivate var mainTabBar:MainTabBarController!
    
    fileprivate var places:HomeViewController!
    fileprivate var messages:MessagesViewController!
    fileprivate var notifications:NotificationsViewController!
    fileprivate var profile:MyProfileViewController!
    
    fileprivate var flashView:UIView!
    fileprivate var uploadCoordinate:CLLocation?
    
    fileprivate var uploadLikelihoods:[GMSPlaceLikelihood]!
    
    fileprivate var flashButton:UIButton!
    fileprivate var switchButton:UIButton!
    fileprivate var locationHeader:LocationHeaderView!
    
    fileprivate var mapView:GMSMapView?
    
    fileprivate var screenMode:ScreenMode = .Main
    
    fileprivate var storyType:StoryType = .UserStory
    
    fileprivate var presentationType:PresentationType = .homeCollection
    
    fileprivate var messageWrapper:SwiftMessages!
    
    fileprivate lazy var cancelButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        button.setImage(UIImage(named: "delete_thick"), for: .normal)
        button.center = CGPoint(x: button.frame.width * 0.60, y: button.frame.height * 0.60)
        button.tintColor = UIColor.white
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
        
    }()
    
    fileprivate lazy var sendButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.setImage(UIImage(named: "send_arrow"), for: .normal)
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.75, y: definiteBounds.height - button.frame.height * 0.75)
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor(red: 69/255, green: 182/255, blue: 73/255, alpha: 1.0)
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.imageEdgeInsets = UIEdgeInsets(top: 6.0, left: 7.0, bottom: 6.0, right: 5.0)
        button.applyShadow(radius: 5, opacity: 0.4, height: 2.5, shouldRasterize: false)
        return button
    }()
    
    fileprivate lazy var captionButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.5, y: button.frame.height * 0.5)
        button.setImage(UIImage(named: "type"), for: .normal)
        button.tintColor = UIColor.white
        button.clipsToBounds = true
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
    }()
    
    fileprivate lazy var locationButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 1.5, y: button.frame.height * 0.5)
        button.setImage(UIImage(named: "poi"), for: .normal)
        button.tintColor = UIColor.white
        button.clipsToBounds = true
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
    }()
    
    fileprivate lazy var textView: UITextView = {
        let definiteBounds = UIScreen.main.bounds
        let textView = UITextView(frame: CGRect(x: 0,y: 0,width: definiteBounds.width,height: 44))
        textView.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        textView.textColor = UIColor.white
        textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        textView.isHidden = false
        textView.keyboardAppearance = .dark
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.backgroundColor = UIColor.clear
        textView.isUserInteractionEnabled = false
        textView.text = "funkymunky"
        textView.fitHeightToContent()
        textView.text = ""
        return textView
    }()
    
    fileprivate lazy var textViewCenter:CGPoint = {
        let mainBounds = UIScreen.main.bounds
        return CGPoint(x: mainBounds.width / 2, y: mainBounds.height / 2)
    }()
    
    fileprivate var textViewPanGesture:UIPanGestureRecognizer?
    fileprivate var textViewTapGesture:UITapGestureRecognizer!
    
    deinit {
        print("Deinit >> MainViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        globalMainInterfaceProtocol = self
        
        messageWrapper = SwiftMessages()
        
        let screenBounds = UIScreen.main.bounds
        view.backgroundColor = UIColor.black
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        textViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(editCaptionTapped))
        
        recordBtn = CameraButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        cameraBtnFrame = recordBtn.frame
        cameraBtnFrame.origin.y = screenBounds.height - cameraBtnFrame.height * 1.8
        cameraBtnFrame.origin.x = self.view.bounds.width/2 - cameraBtnFrame.size.width/2
        recordBtn.frame = cameraBtnFrame
        cameraCenter = recordBtn.center
        recordBtn.applyShadow(radius: 0.67, opacity: 0.67, height: 0.0, shouldRasterize: false)
        
        recordBtnDummy = CameraButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        recordBtnDummy.frame = cameraBtnFrame
        recordBtnDummy.applyShadow(radius: 0.67, opacity: 0.67, height: 0.0, shouldRasterize: false)
        recordBtnDummy.transform = CGAffineTransform(scaleX: 0.55, y: 0.55)
        recordBtnDummy.center = CGPoint(x: cameraCenter.x, y: cameraCenter.y + cameraBtnFrame.height * 0.75)
        recordBtnDummy.ring.layer.borderColor = accentColor.cgColor
        recordBtnDummy.ring.backgroundColor = UIColor.white
    
        
        cameraView = CameraViewController()
        cameraView.recordBtnRef = recordBtn
        cameraView.delegate = self
        cameraView.view.frame = self.view.bounds
        addChildViewController(cameraView)
        view.addSubview(cameraView.view)
        cameraView.didMove(toParentViewController: self)
        
        recordBtn.tappedHandler = recordButtonTapped
        recordBtn.pressedHandler = cameraView.pressed
        
        flashButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        flashButton.setImage(UIImage(named: "flashoff"), for: .normal)
        flashButton.center = CGPoint(x: cameraBtnFrame.origin.x / 2, y: cameraBtnFrame.origin.y + cameraBtnFrame.height / 2)
        flashButton.alpha = 1.0
        flashButton.tintColor = UIColor.white
        flashButton.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        switchButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        switchButton.setImage(UIImage(named: "switchcamera"), for: .normal)
        switchButton.center = CGPoint(x: view.frame.width - cameraBtnFrame.origin.x / 2, y: cameraBtnFrame.origin.y + cameraBtnFrame.height / 2)
        switchButton.alpha = 1.0
        switchButton.tintColor = UIColor.white
        switchButton.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        flashButton.addTarget(self, action: #selector(switchFlashMode), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        
        locationHeader = UINib(nibName: "LocationHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LocationHeaderView
        locationHeader.frame = CGRect(x: 0, y: 20.0, width: view.frame.width, height: 44)
        locationHeader.isHidden = false
        locationHeader.isSearching(true)
        
        let locationHeaderTap = UITapGestureRecognizer(target: self, action: #selector(locationHeaderTapped))
        locationHeader.addGestureRecognizer(locationHeaderTap)
       
        
        let mapViewController  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        mapViewController.view.frame = view.bounds
        mapViewController.locationHeaderRef = locationHeader
        
        let v1  = UIViewController()
        v1.view.backgroundColor = UIColor.clear
        v1.view.frame = view.bounds
        
        mainTabBar  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
        mainTabBar.view.backgroundColor = UIColor.clear
        mainTabBar.view.frame = view.bounds
        
        
        let nav1 = mainTabBar.viewControllers![0] as! UINavigationController
        places = nav1.viewControllers[0] as! HomeViewController
        
        let nav2 = mainTabBar.viewControllers![1] as! UINavigationController
        messages = nav2.viewControllers[0] as! MessagesViewController
        
        
        let nav4 = mainTabBar.viewControllers![3] as! UINavigationController
        notifications = nav4.viewControllers[0] as! NotificationsViewController
        
        let nav5 = mainTabBar.viewControllers![4] as! UINavigationController
        profile = nav5.viewControllers[0] as! MyProfileViewController
        
        var v1Frame: CGRect = CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height)
        v1Frame.origin.y = screenBounds.height
        v1.view.frame = v1Frame
        
        var v2Frame: CGRect = CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height - 20.0)
        v2Frame.origin.y = screenBounds.height * 2 + 20.0
        mainTabBar.view.frame = v2Frame
        
        scrollView = UIScrollView(frame: view.bounds)
        
        addChildViewController(mapViewController)
        scrollView.addSubview(mapViewController.view)
        mapViewController.didMove(toParentViewController: self)
        
        addChildViewController(v1)
        scrollView.addSubview(v1.view)
        v1.didMove(toParentViewController: self)
        
        addChildViewController(mainTabBar)
        scrollView.addSubview(mainTabBar.view)
        mainTabBar.didMove(toParentViewController: self)
        
        scrollView.contentSize = CGSize(width: screenBounds.width, height: screenBounds.height * 3)
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        
        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.black
        flashView.alpha = 0.0
        
        view.addSubview(flashView)
        view.addSubview(scrollView)
        view.addSubview(flashButton)
        view.addSubview(switchButton)
        view.addSubview(locationHeader)
        view.addSubview(recordBtn)
        
        scrollView.setContentOffset(CGPoint(x: 0, y: screenBounds.height * 2.0), animated: false)
        screenMode = .Main
        
        flashView.isUserInteractionEnabled = true
        let autoFocusTap = UITapGestureRecognizer(target: self, action: #selector(focus))
        autoFocusTap.numberOfTapsRequired = 1
        autoFocusTap.numberOfTouchesRequired = 1
        autoFocusTap.delegate = self
        scrollView.addGestureRecognizer(autoFocusTap)
        scrollView.isUserInteractionEnabled = true
        
        let zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoom))
        scrollView.addGestureRecognizer(zoomGesture)
        zoomGesture.delegate = self
        
        if gps_service == nil {
            gps_service = GPSService(["MapViewController":mapViewController, "MainViewController":self])
            gps_service.startUpdatingLocation()
            
            places.gps_service = gps_service
            LocationService.sharedInstance.gps_service = gps_service
            
            authorizationDidChange()
           
        }
        
        if message_service == nil {
            message_service = MessageService([:])
            messages.message_service = message_service
            mainTabBar.message_service = message_service

            message_service.startListeningToConversations()
            
            
        }
        
        if notification_service == nil {
            notification_service = NotificationService([:])
            notifications.notification_service = notification_service
            mainTabBar.notification_service = notification_service
            
            notification_service.startListeningToNotifications()

        }
        mainStore.subscribe(self)
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.activateNavbar(false)
        if cameraView.cameraState == .PhotoTaken || cameraView.cameraState == .VideoTaken {
            statusBar(hide: true, animated: true)
            cameraView.playVideo()
        }
        
        if self.navigationController?.delegate === transitionController {
            if mainTabBar.selectedIndex == 0 {
                places.shouldDelayLoad = true
            }
        }
        textView.resignFirstResponder()
        
    }
    
    func newState(state: AppState) {
        if !state.userState.isAuth {
            places.state.clear()
            message_service.clear()
            notification_service.clear()
            mainStore.unsubscribe(self)
            globalMainInterfaceProtocol = nil
            gps_service = nil
            message_service = nil
            notification_service = nil
            dismiss(animated: false, completion: nil)
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if screenMode == .Camera {
            return true
        }
        return false
    }
    
    
    func focus (_ gestureRecognizer: UITapGestureRecognizer) {
        cameraView.autoFocusGesture(gestureRecognizer)
    }
    
    func zoom(_ gestureRecognizer: UIPinchGestureRecognizer) {
        cameraView.handlePinchGesture(gesture: gestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.navigationController?.delegate === transitionController {
            self.navigationController?.delegate = nil
            recordBtn.isUserInteractionEnabled = true
            scrollView.isScrollEnabled = true
        }
        if cameraView.cameraState == .PhotoTaken || cameraView.cameraState == .VideoTaken {
           //statusBar(hide: true, animated: false)
        } else {
            statusBar(hide: false, animated: true)
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func activateNavbar(_ activate: Bool) {
        guard let nav = self.navigationController as? MasterNavigationController else { return }
        nav.activateNavbar(activate)
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        screenMode = .Transitioning
        recordBtn.removeGestures()
        let scrollViewIndex = view.subviews.index(of: scrollView)!
        let flashButtonIndex = view.subviews.index(of: flashButton)!
        let switchButtonIndex = view.subviews.index(of: switchButton)!
        let locationHeaderIndex = view.subviews.index(of: locationHeader)!
        
        if flashButtonIndex > scrollViewIndex {
           view.exchangeSubview(at: scrollViewIndex, withSubviewAt: flashButtonIndex)
        }
        if switchButtonIndex > scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: switchButtonIndex)
        }
        if locationHeaderIndex > scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: locationHeaderIndex)
        }

        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y
        if y < height {
            let alpha = y / height
            let reverseAlpha = 1 - alpha
            recordBtn.center = CGPoint(x: cameraCenter.x, y: cameraCenter.y + cameraBtnFrame.height * 0.75 * reverseAlpha)
            let multiple = alpha * alpha * alpha * alpha * alpha
            recordBtn.transform = CGAffineTransform(scaleX: 0.55 + 0.15 * multiple, y: 0.55 + 0.15 * multiple)
            recordBtn.ring.layer.borderColor = UIColor.white.cgColor
            recordBtn.ring.backgroundColor = UIColor(white: 1.0, alpha: 0)
            flashButton.center = CGPoint(x: cameraBtnFrame.origin.x / 2 + flashButton.frame.width * reverseAlpha, y: flashButton.center.y)
            flashButton.alpha = multiple
            switchButton.center = CGPoint(x: view.frame.width - cameraBtnFrame.origin.x / 2 - switchButton.frame.width * reverseAlpha, y: switchButton.center.y)
            switchButton.alpha = multiple
            
            //locationHeader.alpha = multiple
            locationHeader.center = CGPoint(x: locationHeader.center.x, y: 20 + 22 - (locationHeader.frame.height * 2.0 * reverseAlpha))
        } else if y > height && y <= height * 2.0 {
            let alpha = (y - height) / height
            let reverseAlpha = 1 - alpha
            recordBtn.center = CGPoint(x: cameraCenter.x, y: cameraCenter.y + cameraBtnFrame.height * 0.75 * alpha)
            let multiple = reverseAlpha * reverseAlpha * reverseAlpha * reverseAlpha * reverseAlpha
            let color = UIColor(hue: 144/360, saturation: (1 - multiple) * 0.99, brightness: 0.85, alpha: 1.0)
                //UIColor(hue: 149/360, saturation: 1 - multiple, brightness: 0.88, alpha: 1.0)
            recordBtn.transform = CGAffineTransform(scaleX: 0.55 + 0.15 * multiple, y: 0.55 + 0.15 * multiple)
            recordBtn.ring.layer.borderColor = color.cgColor
            recordBtn.ring.backgroundColor = UIColor(white: 1.0, alpha: 1 - multiple)
            flashView.alpha = alpha
            flashButton.alpha = multiple
            switchButton.alpha = multiple
            //locationHeader.alpha = multiple
            
            if alpha < 0.98 && cameraView.cameraState == .Off{
                cameraView.cameraState = .Initiating
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y
        if y >= height && y < 10.0 + height {
            globalMainInterfaceProtocol?.fetchAllStories()
            setToCameraMode()
            
            gps_service.setAccurateGPS(true)
        } else if y >= height * 2.0 {
            gps_service.setAccurateGPS(false)
            screenMode = .Main
            cameraView.cameraState = .Off
        } else {
            gps_service.setAccurateGPS(true)
            screenMode = .Map
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
    func setToCameraMode() {
        screenMode = .Camera
        let scrollViewIndex = view.subviews.index(of: scrollView)!
        let flashButtonIndex = view.subviews.index(of: flashButton)!
        let switchButtonIndex = view.subviews.index(of: switchButton)!
        let locationHeaderIndex = view.subviews.index(of: locationHeader)!
        
        if switchButtonIndex < scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: switchButtonIndex)
        }
        if flashButtonIndex < scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: flashButtonIndex)
        }
        
        if locationHeaderIndex < scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: locationHeaderIndex)
        }
        
        recordBtn.center = CGPoint(x: cameraCenter.x, y: cameraCenter.y )

        recordBtn.transform = CGAffineTransform(scaleX: 0.70, y: 0.70)
        recordBtn.ring.layer.borderColor = UIColor.white.cgColor
        recordBtn.ring.backgroundColor = UIColor.clear
        flashView.alpha = 0.0
        recordBtn.addGestures()
    }
    
    func locationHeaderTapped() {
        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    
    
    var statusBarShouldHide = false
    var statusBarIsLight = true
    override var prefersStatusBarHidden: Bool {
        get {
            return statusBarShouldHide
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    public func statusBar(hide: Bool, animated:Bool) {
        statusBarShouldHide = hide
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.setNeedsStatusBarAppearanceUpdate()
            })
        } else {
            self.setNeedsStatusBarAppearanceUpdate()
        }

    }
    
    let transitionController: TransitionController = TransitionController()
    
    func presentNearbyPost(posts:[StoryItem], destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        presentationType = .homeCollection
        
        let galleryViewController: GalleryViewController = GalleryViewController()
        galleryViewController.posts = posts
        galleryViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject, "initialIndexPath": initialIndexPath as AnyObject]
        transitionController.cornerRadius = 0.0
        recordBtn.isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        nav.delegate = transitionController
        transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
    }
    
    func presentBannerStory(presentationType:PresentationType, stories:[Story], destinationIndexPath:IndexPath, initialIndexPath:IndexPath ) {
        guard let nav = self.navigationController else { return }
        self.presentationType = presentationType
        
        let storiesViewController: StoriesViewController = StoriesViewController()
        storiesViewController.stories = stories
        
        transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject,
                                         "initialIndexPath": initialIndexPath as AnyObject]
        transitionController.cornerRadius = 4.5
        storiesViewController.transitionController = transitionController
        
        nav.delegate = transitionController
        recordBtn.isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        transitionController.push(viewController: storiesViewController, on: self, attached: storiesViewController)
    }
    
    func presentUserStory(userStories:[UserStory], destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        presentationType = .homeCollection
        
        let storiesViewController: StoriesViewController = StoriesViewController()
        storiesViewController.stories = userStories
        
        transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject,
                                         "initialIndexPath": initialIndexPath as AnyObject]
        transitionController.cornerRadius = 0.0
        storiesViewController.transitionController = transitionController
        
        nav.delegate = transitionController
        recordBtn.isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        transitionController.push(viewController: storiesViewController, on: self, attached: storiesViewController)

    }
    
    
    func presentProfileStory(posts:[StoryItem], destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        presentationType = .profileCollection
        let galleryViewController: GalleryViewController = GalleryViewController()
        galleryViewController.posts = posts
        galleryViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject, "initialIndexPath": initialIndexPath as AnyObject]
        transitionController.cornerRadius = 0.0
        recordBtn.isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        nav.delegate = transitionController
        transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
    }
    
    func presentNotificationPost(post:StoryItem, destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        presentationType = .notificationTable
        let galleryViewController: GalleryViewController = GalleryViewController()
        galleryViewController.showCommentsOnAppear = true
        galleryViewController.isSingleItem = true
        galleryViewController.posts = [post]
        galleryViewController.transitionController = self.transitionController
        
        self.transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject, "initialIndexPath": initialIndexPath as AnyObject]
        transitionController.cornerRadius = 0.0
        recordBtn.isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        nav.delegate = transitionController
        transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
    }
}

extension MainViewController: CameraDelegate, UITextViewDelegate {
    
    func takingVideo() {
        statusBarShouldHide = true
        self.setNeedsStatusBarAppearanceUpdate()
        UIView.animate(withDuration: 0.42, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func takingPhoto() {
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0
        UIView.animate(withDuration: 0.025, animations: {
            self.flashView.alpha = 0.85
        }, completion: { result in
            UIView.animate(withDuration: 0.25, animations: {
                self.flashView.alpha = 0.0
            }, completion: { result in
                self.flashView.backgroundColor = UIColor.black
            })
        })
    }
    
    func showCameraOptions() {
        scrollView?.isUserInteractionEnabled = true
        flashButton?.isHidden = false
        switchButton?.isHidden = false
        locationHeader?.isHidden = false
    }
    
    func hideCameraOptions() {
        scrollView?.isUserInteractionEnabled = false
        flashButton?.isHidden = true
        switchButton?.isHidden = true
        locationHeader?.isHidden = true
    }
    
    func showEditOptions() {
        statusBarShouldHide = true
        self.setNeedsStatusBarAppearanceUpdate()
        self.view.addSubview(cancelButton)
        self.view.addSubview(sendButton)
        self.view.addSubview(captionButton)
        //self.view.addSubview(locationButton)
        
        textView.resignFirstResponder()
        textView.isUserInteractionEnabled = false
        textView.text = ""
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        textView.textAlignment = .left
        textViewCenter = CGPoint(x: view.frame.width/2, y: view.frame.height - textView.frame.height/2 - sendButton.frame.height - 32.0)
        textView.center = textViewCenter
        self.view.addGestureRecognizer(textViewTapGesture)
        
        self.view.addSubview(textView)
 
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        captionButton.addTarget(self, action: #selector(editCaption), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        uploadCoordinate = gps_service.getLastLocation()
        uploadLikelihoods = gps_service.getLikelihoods()
        
    }

    
    func hideEditOptions() {
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        captionButton.removeFromSuperview()
        //locationButton.removeFromSuperview()
        textView.removeFromSuperview()
        self.view.removeGestureRecognizer(textViewTapGesture)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        cancelButton.removeTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.removeTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        captionButton.removeTarget(self, action: #selector(editCaption), for: .touchUpInside)
        uploadLikelihoods = []
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func editCaptionTapped() {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    func recordButtonTapped() {
        switch screenMode {
        case .Camera:
            cameraView.didPressTakePhoto()
            break
        case .Main:
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.frame.height), animated: true)
            break
        case .Map:
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.frame.height), animated: true)
            break
        case .Transitioning:
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.frame.height), animated: true)
            break
        }
    }
    
    func sendButtonTapped(sender: UIButton) {
        
        if !UserService.isEmailVerified {
            let alert = UIAlertController(title: "Account verification required", message: "Before you post, please verify your email address.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Resend", style: .cancel, handler: { _ in
            
                UserService.sendVerificationEmail { success in
                    if success {
                        let alert = UIAlertController(title: "Email Sent", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                        
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Unable to send email.")
                    }
                }
                
            }))
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        cameraView.pauseVideo()
        
        let upload = Upload()
        if cameraView.cameraState == .PhotoTaken {
            upload.image = cameraView.imageCaptureView.image!
        } else if cameraView.cameraState == .VideoTaken {
            upload.videoURL = cameraView.videoUrl
        }
        
        if textView.text != "" {
            upload.caption = textView.text
        }
        
        upload.coordinates = uploadCoordinate
        //let nav = UIStoryboard(name: "Main", bundle: nil)
           // .instantiateViewController(withIdentifier: "SendNavigationController") as! UINavigationController
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SendViewController") as! SendViewController
        controller.gps_service = gps_service
        controller.upload = upload
        controller.likelihoods = uploadLikelihoods
        controller.cameraViewRef = self.cameraView
        
        
        navigationPush(withController: controller, animated: false)
        
    }
    
    func cancelButtonTapped(sender: UIButton) {
        
        cameraView.destroyVideoPreview()
        
        recordBtn.isHidden = false
        
        if cameraView.captureSession != nil && cameraView.captureSession!.isRunning {
            cameraView.cameraState = .Running
        } else {
            cameraView.cameraState = .Initiating
        }
    }
    
    func editCaption(sender: UIButton) {
        textView.becomeFirstResponder()
    }
    
    func keyboardWillAppear(notification: NSNotification) {
        
        guard let info = notification.userInfo else { return }
        guard let keyboardValue = info[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame: CGRect = keyboardValue.cgRectValue
        
        captionButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.view.frame.height
            let textViewFrame = self.textView.frame
            self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.65)
            self.textView.center = CGPoint(x: self.textViewCenter.x, y: height - keyboardFrame.height - textViewFrame.height / 2)
        }, completion: { _ in
            self.textView.isUserInteractionEnabled = true
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification) {
       
        //textView.isUserInteractionEnabled = false
        captionButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            /*let height = self.view.frame.height
            let textViewFrame = self.textView.frame
            let textViewStart = height - textViewFrame.height - 90
            self.textView.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)*/
            self.textView.center = self.textViewCenter
            if self.textView.text != "" {
                self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.65)
            } else {
                self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
            }
        })
    }
    
    func updateTextAndCommentViews() {
        let oldHeight = textView.frame.size.height
        textView.fitHeightToContent()
        let change = textView.frame.height - oldHeight
        
        textView.center = CGPoint(x: textView.center.x, y: textView.center.y - change)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        updateTextAndCommentViews()
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
    
    func switchFlashMode(sender:UIButton!) {
        if let avDevice = cameraView.cameraDevice
        {
            // check if the device has torch
            if avDevice.hasTorch {
                // lock your device for configuration
                do {
                    _ = try avDevice.lockForConfiguration()
                } catch {
                }
                switch cameraView.flashMode {
                case .On:
                    
                    avDevice.flashMode = .auto
                    cameraView.flashMode = .Auto
                    flashButton.setImage(UIImage(named: "flashauto"), for: .normal)
                    break
                case .Auto:
                    avDevice.flashMode = .off
                    cameraView.flashMode = .Off
                    flashButton.setImage(UIImage(named: "flashoff"), for: .normal)
                    break
                case .Off:
                    avDevice.flashMode = .on
                    cameraView.flashMode = .On
                    flashButton.setImage(UIImage(named: "flashon"), for: .normal)
                    break
                }
                // unlock your device
                avDevice.unlockForConfiguration()
            }
        }
        
    }
    
    func switchCamera(sender:UIButton!) {
        switch cameraView.cameraMode {
        case .Back:
            flashButton.isHidden = false
            cameraView.cameraMode = .Front
            break
        case .Front:
            flashButton.isHidden = true
            cameraView.cameraMode = .Back
            break
        }
        cameraView.reloadCamera()
    }
    
}

extension MainViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath else {
            return CGRect.zero
        }
        
        let i =  IndexPath(row: indexPath.item, section: 0)
        switch presentationType {
        case .homeCollection:
            let cell: PhotoCell = places.collectionView!.cellForItem(at: indexPath)! as! PhotoCell
            let convertedFrame = cell.imageView.convert(cell.imageView.frame, to: self.view)
            return convertedFrame
        case .homeHeader:
            guard let headerCollectionView = places.topCollectionViewRef else { return CGRect.zero }
            guard let cell = headerCollectionView.cellForItem(at: indexPath) as? FollowingPhotoCell else { return CGRect.zero }
            let convertedFrame = cell.convert(cell.container.frame, to: self.view)
            return convertedFrame
        case .homeNearbyHeader:
            guard let headerCollectionView = places.midCollectionViewRef else { return CGRect.zero }
            guard let cell = headerCollectionView.cellForItem(at: indexPath) as? FollowingPhotoCell else { return CGRect.zero }
            let convertedFrame = cell.convert(cell.container.frame, to: self.view)
            return convertedFrame
        case .notificationTable:
            let cell: NotificationTableViewCell = notifications.tableView.cellForRow(at: i)! as! NotificationTableViewCell
            let image_frame = cell.postImageView.frame
            let navHeight = self.navigationController!.navigationBar.frame.height + 20.0
            let y = cell.frame.origin.y + image_frame.origin.y + navHeight - notifications.tableView.contentOffset.y//+ navHeight
            let rect = CGRect(x: image_frame.origin.x, y: y, width: image_frame.width, height: image_frame.height)// CGRectMake(x,y,image_height, image_height)
            return view.convert(rect, to: view)
        case .profileCollection:
            let cell: PhotoCell = profile.collectionView!.cellForItem(at: i)! as! PhotoCell
            let convertedFrame = cell.imageView.convert(cell.imageView.frame, to: self.view)
            return convertedFrame
        }

    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        switch presentationType {
        case .homeCollection:
            guard let cell: PhotoCell = places.collectionView!.cellForItem(at: indexPath) as? PhotoCell else { return UIView() }
            return cell
        case .homeHeader:
            guard let cell = places.topCollectionViewRef?.cellForItem(at: indexPath) as? FollowingPhotoCell else { return UIView() }
            return cell.container
        case .homeNearbyHeader:
            guard let cell = places.midCollectionViewRef?.cellForItem(at: indexPath) as? FollowingPhotoCell else { return UIView() }
            return cell.container
        case .notificationTable:
            let cell: NotificationTableViewCell = notifications.tableView.cellForRow(at: indexPath)! as! NotificationTableViewCell
            return cell.postImageView
        case .profileCollection:
            guard let cell: PhotoCell = profile.collectionView!.cellForItem(at: i) as? PhotoCell else {
                return UIView()
            }
            return cell
        }
        
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        
        if !isPresenting {
            switch presentationType {
            case .homeCollection:
                if !places.collectionView!.indexPathsForVisibleItems.contains(indexPath) {
                    places.collectionView!.reloadData()
                    places.collectionView!.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                    places.collectionView!.layoutIfNeeded()
                }
                break
            case .homeHeader:
                if let bannerCollectionView = places.topCollectionViewRef {
                    if !bannerCollectionView.indexPathsForVisibleItems.contains(indexPath) {
                        bannerCollectionView.reloadData()
                        bannerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                        bannerCollectionView.layoutIfNeeded()
                    }
                }
                break
            case .homeNearbyHeader:
                if let bannerCollectionView = places.midCollectionViewRef {
                    if !bannerCollectionView.indexPathsForVisibleItems.contains(indexPath) {
                        bannerCollectionView.reloadData()
                        bannerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                        bannerCollectionView.layoutIfNeeded()
                    }
                }
                break
            case .notificationTable:
                break
            case .profileCollection:
                if !profile.collectionView!.indexPathsForVisibleItems.contains(indexPath) {
                    profile.collectionView!.reloadData()
                    profile.collectionView!.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                    profile.collectionView!.layoutIfNeeded()
                }
                break
            }
        }
    }
    
    func dismissInteractionEnded(_ completed: Bool) {}
    
    func cameraButtonView() -> UIView {
        return recordBtnDummy
    }
    
    func topView() -> UIView {
        if presentationType == .homeCollection || presentationType == .homeHeader || presentationType == .homeNearbyHeader {
            if let view = places.header.snapshotImageTransparent() {
                let topView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0 + 20.0))
                topView.backgroundColor = UIColor.black
                
                let bottomEdge = UIView(frame: CGRect(x: 0, y: topView.frame.height - 32.0, width: topView.frame.width, height: 32.0))
                bottomEdge.backgroundColor = UIColor.white
                
                let white = UIView(frame: CGRect(x: 0, y: 20.0, width: topView.frame.width, height: 44.0))
                white.backgroundColor = UIColor.white
                white.layer.cornerRadius = 16.0
                white.clipsToBounds = true
                let t = UIImageView(frame: CGRect(x: 0, y: 20.0, width: topView.frame.width, height: 44.0))
                t.image = view
                topView.addSubview(bottomEdge)
                topView.addSubview(white)
                topView.addSubview(t)
                return topView
            }
        }

        return UIView()
    }
    
    func bottomView() -> UIView {
        if let view = mainTabBar.tabBar.snapshotImage() {
            let t = UIImageView(frame: mainTabBar.tabBar.frame)
            t.image = view
            return t
        }
        return UIView()
    }
    
}

extension MainViewController: GPSServiceProtocol {
    func tracingLocation(_ currentLocation: CLLocation) {}
    func significantLocationUpdate( _ location: CLLocation) {}
    func tracingLocationDidFailWithError(_ error: NSError) {}
    func nearbyPlacesUpdate(_ likelihoods:[GMSPlaceLikelihood]) {}
    func horizontalAccuracyUpdated(_ accuracy:Double?) {}
    func authorizationDidChange() {
        
    }
}


enum CameraState {
    case Off, Initiating, Running, DidPressTakePhoto, PhotoTaken, VideoTaken, Recording
}

enum CameraMode {
    case Front, Back
}

enum FlashMode {
    case Off, On, Auto
}

enum ScreenMode {
    case Transitioning, Camera, Map, Main
}

enum StoryType {
    case NearbyPost, UserStory, ProfileStory, NotificationPost
}

enum PresentationType {
    case homeCollection, homeHeader, homeNearbyHeader, profileCollection, notificationTable
}
