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
import Firebase

var globalMainInterfaceProtocol:MainInterfaceProtocol?

protocol MainInterfaceProtocol {
    func setScrollState(_ enabled:Bool)
    func navigationPush(withController controller: UIViewController, animated: Bool)
    func presentPopover(withController controller: UIViewController, animated: Bool)
    func presentHomeScreen(animated: Bool)
    func presentCamera()
    func fetchAllStories()
    func statusBar(hide: Bool, animated:Bool)
    func presentNearbyPost(presentationType: PresentationType, posts:[StoryItem], destinationIndexPath:IndexPath, initialIndexPath:IndexPath)
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
        //cameraView.cameraState = .Initiating
        scrollView.setContentOffset(CGPoint(x: 0, y: view.frame.height * 1.0), animated: animated)
        mainTabBar.selectedIndex = 0
        scrollView.isScrollEnabled = false
        
    }
    
    func presentCamera() {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    func fetchAllStories() {
        //places?.state.fetchAll()
        homie?.state.fetchAll()
        LocationService.sharedInstance.requestNearbyLocations()
        
    }
}

class MainViewController: UIViewController, StoreSubscriber, UIScrollViewDelegate, UIGestureRecognizerDelegate, CameraPermissionsProtocol {

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
    fileprivate var homie:HomieViewController!
    fileprivate var messages:MessagesViewController!
    fileprivate var notifications:NotificationsViewController!
    fileprivate var profile:MyProfileViewController!
    
    fileprivate var flashView:UIView!
    fileprivate var uploadCoordinate:CLLocation?
    fileprivate var uploadPlace:GMSPlaceLikelihood?
    
    fileprivate var uploadLikelihoods:[GMSPlaceLikelihood]!
    
    fileprivate var flashButton:UIButton!
    fileprivate var switchButton:UIButton!
    fileprivate var homeButton:UIButton!
    
    
    fileprivate var screenMode:ScreenMode = .Main
    
    fileprivate var storyType:StoryType = .UserStory
    
    fileprivate var presentationType:PresentationType = .homeCollection
    
    fileprivate var messageWrapper:SwiftMessages!
    

    
    fileprivate lazy var editOptionsBar: PostEditOptionsBar = {
        let definiteBounds = UIScreen.main.bounds
        let view = UINib(nibName: "PostEditOptionsBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PostEditOptionsBar
        view.frame = CGRect(x: 0, y: 0, width: definiteBounds.width, height: 64)
        view.applyShadow(radius: 3.0, opacity: 0.20, height: 0.0, shouldRasterize: false)
        return view
    }()
    
    fileprivate lazy var sendOptionsBar: PostSendOptionsBar = {
        let definiteBounds = UIScreen.main.bounds
        let view = UINib(nibName: "PostSendOptionsBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PostSendOptionsBar
        view.frame = CGRect(x: 0, y: definiteBounds.height - 64, width: definiteBounds.width, height: 64)
        view.applyShadow(radius: 3.0, opacity: 0.20, height: 0.0, shouldRasterize: false)
        return view
    }()
    
    
    fileprivate lazy var textView: UITextView = {
        let definiteBounds = UIScreen.main.bounds
        let textView = UITextView(frame: CGRect(x: 8,y: 0,width: definiteBounds.width - 16,height: 44))
        textView.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        textView.textColor = UIColor.white
        textView.isHidden = false
        textView.keyboardAppearance = .dark
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.isUserInteractionEnabled = false
        textView.text = "funkymunky"
        textView.fitHeightToContent()
        textView.text = ""

        
        textView.layer.cornerRadius = 8.0
        textView.clipsToBounds = true
        
        textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        
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
        
        homeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        homeButton.setImage(UIImage(named:"bluedot"), for: .normal)
        homeButton.center = CGPoint(x: view.center.x, y: view.frame.height - 26)
        homeButton.alpha = 0.35
        homeButton.tintColor = UIColor.white
        homeButton.imageEdgeInsets = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0)

        homeButton.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        flashButton.addTarget(self, action: #selector(switchFlashMode), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        homeButton.addTarget(self, action: #selector(goHome), for: .touchUpInside)
        
        let v1  = UIViewController()
        v1.view.backgroundColor = UIColor.clear
        v1.view.frame = view.bounds
        
        mainTabBar  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
        mainTabBar.view.backgroundColor = UIColor.clear
        mainTabBar.view.frame = view.bounds
        
        
        let nav1 = mainTabBar.viewControllers![0] as! UINavigationController
        homie = nav1.viewControllers[0] as! HomieViewController
        
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
        v2Frame.origin.y = screenBounds.height * 1 + 20.0
        mainTabBar.view.frame = v2Frame
        
        scrollView = UIScrollView(frame: view.bounds)
        
        addChildViewController(v1)
        scrollView.addSubview(v1.view)
        v1.didMove(toParentViewController: self)
        
        addChildViewController(mainTabBar)
        scrollView.addSubview(mainTabBar.view)
        mainTabBar.didMove(toParentViewController: self)
        
        scrollView.contentSize = CGSize(width: screenBounds.width, height: screenBounds.height * 2)
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = false
        
        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0
        
        view.addSubview(flashView)
        view.addSubview(scrollView)
        view.addSubview(flashButton)
        view.addSubview(switchButton)
        view.addSubview(homeButton)
        view.addSubview(recordBtn)
        
        scrollView.setContentOffset(CGPoint(x: 0, y: screenBounds.height * 1.0), animated: false)
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
            gps_service = GPSService(["MainViewController":self])
            homie.gps_service = gps_service
            LocationService.sharedInstance.gps_service = gps_service
            
            gps_service.startUpdatingLocation()
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
        
        
        registerForNotifications()
    }
    
    var cameraPermissionsView:CameraPermissionsView?
    
    func isCameraPermitted() -> Bool{
        
        let verified = UserService.isEmailVerified
        
        let locationPermission = gps_service.isAuthorized()
        
        let cameraPermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized
        print("cameraPermission: \(cameraPermission)")
        
        let microphonePermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized
        print("microphonePermission: \(microphonePermission)")
        
        if (verified && locationPermission && cameraPermission && microphonePermission) {
            return true
        }
        
        cameraPermissionsView = UINib(nibName: "CameraPermissionsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CameraPermissionsView
        cameraPermissionsView!.setup(verified: verified, locationEnabled: locationPermission, cameraAllowed: cameraPermission, microphoneAllowed: microphonePermission)
        cameraPermissionsView!.delegate = self
        let messageView = BaseView(frame: view.bounds)
        messageView.installContentView(cameraPermissionsView!)
        messageView.preferredHeight = view.bounds.height
        
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .center
        config.duration = .forever
        config.dimMode = .blur(style: .dark, alpha: 1.0, interactive: true)
        config.presentationContext  = .window(windowLevel: UIWindowLevelStatusBar)
        messageWrapper.show(config: config, view: messageView)

        return false
    }
    
    func dismissPermissionsView() {
        messageWrapper.hideAll()
    }
    
    func resendTapped() {

//
        guard let permissionsView = self.cameraPermissionsView else { return }
        if !UserService.isEmailVerified {
        
            if permissionsView.refreshMode {
                
                Auth.auth().currentUser?.reload() { error in
                    if error == nil {
                        
                        mainStore.dispatch(FIRUserUpdated())
                        if UserService.isEmailVerified {
                            permissionsView.removeVerifyView()
                            self.checkCameraPermissions()
                        } else {
                            permissionsView.setToResendMode()
                        }
                        
                    }
                }
                
            } else {
                UserService.sendVerificationEmail { success in
                    if success {
                        permissionsView.setToRefreshMode()
                    } else {
                        
                    }
                }

            }
            
            
        } else {
            self.cameraPermissionsView?.removeVerifyView()
            self.checkCameraPermissions()
        }
    }
    
    var requestingLocationAuthorization = false
    
    func enableLocationTapped() {
        let gpsStatus = gps_service.authorizationStatus()
        if gpsStatus == .denied || gpsStatus == .restricted {
            
            if #available(iOS 10.0, *) {
                let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)! as URL
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            } else {
                let alert = UIAlertController(title: "Go to Settings", message: "Please minimize Jungle and go to your settings to enable location services.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        } else if gpsStatus == .notDetermined {
            requestingLocationAuthorization = true
            gps_service.requestAuthorization()
        }
        
    }
    
    func allowCameraTapped() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if cameraStatus == .denied || cameraStatus == .restricted {
            if #available(iOS 10.0, *) {
                let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)! as URL
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            } else {
                let alert = UIAlertController(title: "Go to Settings", message: "Please minimize Jungle and go to your settings to allow camera usage.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        } else if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted: Bool) -> Void in
                DispatchQueue.main.async() {
                    if granted {
                        self.cameraPermissionsView?.removeCameraView()
                        self.checkCameraPermissions()
                    }
                }
            })
        }
    }
    
    func allowMicrophoneTapped() {
        let microphoneStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)
        if microphoneStatus == .denied || microphoneStatus == .restricted {
            if #available(iOS 10.0, *) {
                let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)! as URL
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            } else {
                let alert = UIAlertController(title: "Go to Settings", message: "Please minimize Jungle and go to your settings to allow microphone usage.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        } else if microphoneStatus == .notDetermined {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (granted: Bool) -> Void in
                DispatchQueue.main.async() {
                    if granted {
                        self.cameraPermissionsView?.removeMicrophoneView()
                        self.checkCameraPermissions()
                    }
                }
            })
        }
    }
    
    func checkCameraPermissions() {
        let verified = UserService.isEmailVerified
        let locationPermission = gps_service.isAuthorized()
        let cameraPermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized
        let microphonePermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized
        
        if (verified && locationPermission && cameraPermission && microphonePermission) {
            messageWrapper.hideAll()
            mainTabBar.view.isUserInteractionEnabled = false
            cameraView.cameraState = .Initiating
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.activateNavbar(false)
        if cameraView.cameraState == .PhotoTaken || cameraView.cameraState == .VideoTaken {
            statusBar(hide: true, animated: true)
            cameraView.playVideo()
        }
        
        if self.navigationController?.delegate === transitionController {
            if mainTabBar.selectedIndex == 0 {
                //places.shouldDelayLoad = true
            }
        }
        textView.resignFirstResponder()

        
    }
    
    func newState(state: AppState) {
        if !state.userState.isAuth {
            //places.state.clear()
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
    
    func registerForNotifications() {
        notification_service.notificationsEnabled() { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.notification_service.registerForNotifications()
                    break
                case .denined:
                    let messageView: MessageView = MessageView.viewFromNib(layout: .CenteredView)
                    messageView.configureBackgroundView(width: 250)
                    messageView.configureContent(title: "Notifications are disabled", body: "To enable notifications, go to your settings and turn on notifications for Jungle.", iconImage: nil, iconText: "🔕", buttonImage: nil, buttonTitle: "Go to settings") { _ in
                        self.messageWrapper.hide()
                        let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)! as URL
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                        } else {
                            let alert = UIAlertController(title: "Go to Settings", message: "Please minimize Jungle and go to your settings to enable notifications.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                    let button = messageView.button!
                    button.backgroundColor = infoColor
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
                    break
                case .notDetermined:
                    let messageView: MessageView = MessageView.viewFromNib(layout: .CenteredView)
                    messageView.configureBackgroundView(width: 250)
                    messageView.configureContent(title: "Recieve notifications?", body: "You will recieve alerts about new followers, messages, and activity on posts that you are subscribed to.", iconImage: nil, iconText: "🔔", buttonImage: nil, buttonTitle: "Enable Notifications") { _ in
                        self.notification_service.registerForNotifications()
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
                    
                    let gradient = CAGradientLayer()
                    gradient.frame = button.bounds
                    gradient.colors = [
                        lightAccentColor.cgColor,
                        darkAccentColor.cgColor
                    ]
                    gradient.locations = [0.0, 1.0]
                    gradient.startPoint = CGPoint(x: 0, y: 0)
                    gradient.endPoint = CGPoint(x: 1, y: 0)
                    button.layer.insertSublayer(gradient, at: 0)
                    
                    messageView.backgroundView.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
                    messageView.backgroundView.layer.cornerRadius = 12
                    var config = SwiftMessages.defaultConfig
                    config.presentationStyle = .center
                    config.duration = .forever
                    config.dimMode = .blur(style: .dark, alpha: 1.0, interactive: true)
                    config.presentationContext  = .window(windowLevel: UIWindowLevelStatusBar)
                    self.messageWrapper.show(config: config, view: messageView)
                    break
                }
            }
        }
    }
    
    
    func activateNavbar(_ activate: Bool) {
        guard let nav = self.navigationController as? MasterNavigationController else { return }
        nav.activateNavbar(activate)
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != self.scrollView { return }
        screenMode = .Transitioning
        recordBtn.removeGestures()
        let scrollViewIndex = view.subviews.index(of: scrollView)!
        let flashButtonIndex = view.subviews.index(of: flashButton)!
        let switchButtonIndex = view.subviews.index(of: switchButton)!
        let homeButtonIndex = view.subviews.index(of: homeButton)!
        
        if flashButtonIndex > scrollViewIndex {
           view.exchangeSubview(at: scrollViewIndex, withSubviewAt: flashButtonIndex)
        }
        if switchButtonIndex > scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: switchButtonIndex)
        }
        
        if homeButtonIndex > scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: homeButtonIndex)
        }

        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y

        let alpha = y / height
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
        homeButton.alpha = multiple * 0.5
        
        if alpha < 0.98 && cameraView.cameraState == .Off{
            //cameraView.cameraState = .Initiating
        }
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y
        if y < height {
            mainTabBar.view.isUserInteractionEnabled = true
            globalMainInterfaceProtocol?.fetchAllStories()
            setToCameraMode()
            scrollView.isScrollEnabled = true
            gps_service.setAccurateGPS(true)
        } else  {
            scrollView.isScrollEnabled = false
            gps_service.setAccurateGPS(false)
            screenMode = .Main
            cameraView.cameraState = .Off
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
        let homeButtonIndex = view.subviews.index(of: homeButton)!
        
        if homeButtonIndex < scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: homeButtonIndex)
        }
        
        if switchButtonIndex < scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: switchButtonIndex)
        }
        if flashButtonIndex < scrollViewIndex {
            view.exchangeSubview(at: scrollViewIndex, withSubviewAt: flashButtonIndex)
        }
        
        recordBtn.center = CGPoint(x: cameraCenter.x, y: cameraCenter.y )

        recordBtn.transform = CGAffineTransform(scaleX: 0.70, y: 0.70)
        recordBtn.ring.layer.borderColor = UIColor.white.cgColor
        recordBtn.ring.backgroundColor = UIColor.clear
        flashView.alpha = 0.0
        recordBtn.addGestures()
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
            return .default
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
    
    func presentNearbyPost(presentationType:PresentationType, posts:[StoryItem], destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        self.presentationType = presentationType
        
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

extension MainViewController: CameraDelegate, UITextViewDelegate, EditOptionsBarProtocol, SendOptionsBarProtocol {
    
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
                self.flashView.backgroundColor = UIColor.white
            })
        })
    }
    
    func showCameraOptions() {
        scrollView?.isUserInteractionEnabled = true
        flashButton?.isHidden = false
        switchButton?.isHidden = false
        homeButton?.isHidden = false
    }
    
    func hideCameraOptions() {
        scrollView?.isUserInteractionEnabled = false
        flashButton?.isHidden = true
        switchButton?.isHidden = true
        homeButton?.isHidden = true
    }
    
    func showEditOptions() {
        statusBarShouldHide = true
        self.setNeedsStatusBarAppearanceUpdate()
        self.view.addSubview(editOptionsBar)
        self.view.addSubview(sendOptionsBar)
        
        
        editOptionsBar.alpha = 1.0
        sendOptionsBar.userImage.alpha = 1.0
        sendOptionsBar.send.setTitleColor(UIColor.white, for: .normal)
        sendOptionsBar.isUserInteractionEnabled = true
        editOptionsBar.isUserInteractionEnabled = true
        editOptionsBar.delegate = self
        sendOptionsBar.delegate = self
        sendOptionsBar.setup()
        
        //self.view.addSubview(locationButton)
        
        textView.resignFirstResponder()
        textView.isUserInteractionEnabled = true
        textView.text = ""
        textView.delegate = self
        textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        textView.textAlignment = .left
        textViewCenter = CGPoint(x: view.frame.width/2, y: view.frame.height - textView.frame.height/2 - sendOptionsBar.frame.height - 8.0)
        textView.center = textViewCenter
        self.view.removeGestureRecognizer(textViewTapGesture)
        self.view.addGestureRecognizer(textViewTapGesture)
        
        self.view.addSubview(textView)
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        uploadCoordinate = gps_service.getLastLocation()
        uploadLikelihoods = gps_service.getLikelihoods()
        
    }

    
    func hideEditOptions() {
        editOptionsBar.setLocationName(nil)
        editOptionsBar.removeFromSuperview()
        sendOptionsBar.removeFromSuperview()
        editOptionsBar.delegate = nil
        sendOptionsBar.delegate = nil
        textView.isUserInteractionEnabled = false
        textView.removeFromSuperview()
        
        
        self.view.removeGestureRecognizer(textViewTapGesture)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        uploadLikelihoods = []
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func editCaptionTapped(_ gesture:UITapGestureRecognizer) {
        
        let point = gesture.location(ofTouch: 0, in: self.view)
        
        if point.y < editOptionsBar.frame.height || point.y > textView.frame.origin.y { return }
        
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    var cameraPermissionsGranted:Bool {
        get {
            return false
        }
    }
    
    func cameraReady() {
        
        scrollView.isScrollEnabled = true
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    func recordButtonTapped() {
        switch screenMode {
        case .Camera:
            cameraView.didPressTakePhoto()
            break
            
        case .Main:
            
            if isCameraPermitted() {
                mainTabBar.view.isUserInteractionEnabled = false
                cameraView.cameraState = .Initiating
            }
            
            break
        case .Map:
            break
        case .Transitioning:
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
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
    
    func editCancel() {
        
        uploadPlace = nil
        uploadCoordinate = nil
        editOptionsBar.setLocationName(nil)
        cameraView.destroyVideoPreview()
        
        recordBtn.isHidden = false
        
        if cameraView.captureSession != nil && cameraView.captureSession!.isRunning {
            cameraView.cameraState = .Running
        } else {
            cameraView.cameraState = .Initiating
        }
    }
    
    func editLocation() {
        let height = view.frame.height * 0.45
        let sortOptionsView = UINib(nibName: "LocationPickerView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LocationPickerView
        sortOptionsView.places = gps_service.getLikelihoods()
        sortOptionsView.setup()
        sortOptionsView.locationPicked = { place in
            self.uploadPlace = place
            if place != nil {
                self.editOptionsBar.setLocationName(place!.place.name)
            } else {
                self.editOptionsBar.setLocationName(nil)
            }
            self.messageWrapper.hide()
        }
        
        let f = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
        let messageView = BaseView(frame: f)
        messageView.installContentView(sortOptionsView)
        messageView.preferredHeight = height
        messageView.configureDropShadow()
        var config = SwiftMessages.defaultConfig
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .forever
        config.presentationStyle = .bottom
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true
        messageWrapper.show(config: config, view: messageView)
    }
    
    func editCaption() {
        textView.becomeFirstResponder()
    }
    
    func sendPost() {
        
        if !mainStore.state.settingsState.uploadWarningShown {
            
            let alert = UIAlertController(title: "Heads up!", message: "All posts on Jungle are public and can be seen by anyone (except for users you have blocked). Don't post anything too personal.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Nevermind", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in
                mainStore.dispatch(UploadWarningShown())
                UserService.ref.child("users/settings/\(mainStore.state.userState.uid)/upload_warning_shown").setValue(true)
                self.uploadPost()
            }))
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        uploadPost()
        
    }
    
    func uploadPost() {
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
        upload.place = uploadPlace?.place
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.startAnimating()
        activityIndicator.center = sendOptionsBar.center
        view.addSubview(activityIndicator)
        
        sendOptionsBar.send.setTitleColor(UIColor.clear, for: .normal)
        
        editOptionsBar.isUserInteractionEnabled = false
        sendOptionsBar.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.20, animations: {
            self.editOptionsBar.alpha = 0.0
            self.sendOptionsBar.userImage.alpha = 0.0
        })
        
        
        
        if let videoURL = upload.videoURL {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let outputUrl = documentsURL.appendingPathComponent("output.mp4")
            
            do {
                try FileManager.default.removeItem(at: outputUrl)
            }
            catch let error as NSError {
                if error.code != 4 && error.code != 2 {
                    return print("Error \(error)")
                }
            }
            upload.videoURL = outputUrl
            
            UIView.animate(withDuration: 0.20, animations: {
                self.editOptionsBar.alpha = 0.0
                self.sendOptionsBar.userImage.alpha = 0.0
            })
            
            UploadService.compressVideo(inputURL: videoURL, outputURL: outputUrl, handler: { session in
                DispatchQueue.main.async {
                    activityIndicator.removeFromSuperview()
                    self.sent()
                    UploadService.getUploadKey(upload: upload) { success in
                        
                    }
                }
            })
            
        } else if upload.image != nil {
            UIView.animate(withDuration: 0.20, animations: {
                self.editOptionsBar.alpha = 0.0
                self.sendOptionsBar.userImage.alpha = 0.0
            }, completion: { _ in
                UIView.animate(withDuration: 0.5, animations: {
                    
                }, completion: { _ in
                    DispatchQueue.main.async {
                        activityIndicator.removeFromSuperview()
                        self.sent()
                    }
                })
            })
            UploadService.getUploadKey(upload: upload) { success in
                
            }
        }
    }
    
    func sent() {
        cameraView.cameraState = .Off
        mainTabBar.view.isUserInteractionEnabled = true
        presentHomeScreen(animated: false)
        scrollView.isScrollEnabled = false
        screenMode = .Main
    }

    
    func keyboardWillAppear(notification: NSNotification) {
        
        
        guard let info = notification.userInfo else { return }
        guard let keyboardValue = info[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame: CGRect = keyboardValue.cgRectValue
        
        //captionButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.view.frame.height
            let textViewFrame = self.textView.frame
            self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            self.textView.center = CGPoint(x: self.textViewCenter.x, y: height - keyboardFrame.height - textViewFrame.height / 2 - 8.0)
        }, completion: { _ in
            self.textView.isUserInteractionEnabled = true
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification) {
       
        //textView.isUserInteractionEnabled = false
        //captionButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            /*let height = self.view.frame.height
            let textViewFrame = self.textView.frame
            let textViewStart = height - textViewFrame.height - 90
            self.textView.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)*/
            self.textView.center = self.textViewCenter
            if self.textView.text != "" {
                
                self.textView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
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
        self.textViewCenter = CGPoint(x: textViewCenter.x, y: textViewCenter.y - change / 2)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        textView.yo()
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
    
    func goHome() {
        scrollView.setContentOffset(CGPoint(x: 0, y: view.frame.height * 1.0), animated: true)
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
        case .popular:
            guard let headerCollectionView = places.homeHeader?.popularCollectionView else { return CGRect.zero }
            guard let cell = headerCollectionView.cellForItem(at: indexPath) as? PhotoCell else { return CGRect.zero }
            let convertedFrame = cell.imageView.convert(cell.imageView.frame, to: self.view)
            return CGRect(x: convertedFrame.origin.x, y: convertedFrame.origin.y, width: convertedFrame.width, height: convertedFrame.height)

        case .following:
            guard let headerCollectionView = places.homeHeader?.followingCollectionView else { return CGRect.zero }
            guard let cell = headerCollectionView.cellForItem(at: indexPath) as? FollowingPhotoCell else { return CGRect.zero }
            let convertedFrame = cell.convert(cell.container.frame, to: self.view)
            return convertedFrame
        case .places:
            guard let headerCollectionView = places.homeHeader?.placesCollectionView else { return CGRect.zero }
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
        case .popular:
            guard let cell = places.homeHeader?.popularCollectionView.cellForItem(at: indexPath) as? PhotoCell else { return UIView() }
            return cell
        case .following:
            guard let cell = places.homeHeader?.followingCollectionView.cellForItem(at: indexPath) as? FollowingPhotoCell else { return UIView() }
            return cell.container
        case .places:
            guard let cell = places.homeHeader?.placesCollectionView.cellForItem(at: indexPath) as? FollowingPhotoCell else { return UIView() }
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
            case .popular:
                if let bannerCollectionView = places.homeHeader?.popularCollectionView {
                    if !bannerCollectionView.indexPathsForVisibleItems.contains(indexPath) {
                        bannerCollectionView.reloadData()
                        bannerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                        bannerCollectionView.layoutIfNeeded()
                    }
                }
                break
            case .following:
                if let bannerCollectionView = places.homeHeader?.followingCollectionView {
                    if !bannerCollectionView.indexPathsForVisibleItems.contains(indexPath) {
                        bannerCollectionView.reloadData()
                        bannerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                        bannerCollectionView.layoutIfNeeded()
                    }
                }
                break
            case .places:
                if let bannerCollectionView = places.homeHeader?.placesCollectionView {
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
        if presentationType == .homeCollection || presentationType == .popular || presentationType == .following || presentationType == .places {
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
    func significantLocationUpdate( _ location: CLLocation) {
        print("LOCATION UPDATED")
        //places?.state.getNearby()
        homie?.state.getNearby()
    }
    func tracingLocationDidFailWithError(_ error: NSError) {}
    func nearbyPlacesUpdate(_ likelihoods:[GMSPlaceLikelihood]) {}
    func horizontalAccuracyUpdated(_ accuracy:Double?) {}
    func authorizationDidChange(_ status: CLAuthorizationStatus) {
        //places?.collectionView?.reloadData()
        homie?.collectionView?.reloadData()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.cameraPermissionsView?.removeLocationView()
            
            if requestingLocationAuthorization {
                self.checkCameraPermissions()
                requestingLocationAuthorization = false
            }
        }
        
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
    case homeCollection, popular, following, places, profileCollection, notificationTable
}
