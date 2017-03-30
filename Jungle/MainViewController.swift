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

var globalMainRef:MainViewController?

class MainViewController: UIViewController, UIScrollViewDelegate {

    var gps_service:GPSService!
    
    var scrollView:UIScrollView!
    
    var cameraView:CameraViewController!
    var recordBtn:CameraButton!
    var cameraBtnFrame:CGRect!
    var cameraCenter:CGPoint!
    
    
    var places:PlacesViewController!
    var profile:MyProfileViewController!
    
    var returningPlacesCell:PhotoCell?
    var returningStoriesCell:UserStoryCollectionViewCell?
    var flashView:UIView!
    
    var uploadLikelihoods:[GMSPlaceLikelihood]!
    
    var flashButton:UIButton!
    var switchButton:UIButton!
    var locationHeader:LocationHeaderView!
    
    var mapView:GMSMapView?
    var mapContainer:UIView!
    
    var screenMode:ScreenMode = .Camera
    
    var storyType:StoryType = .PlaceStory
    
    lazy var cancelButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.center = CGPoint(x: button.frame.width * 0.60, y: button.frame.height * 0.60)
        button.tintColor = UIColor.white
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
        
    }()
    
    lazy var sendButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        button.setImage(UIImage(named: "send_arrow"), for: .normal)
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.75, y: definiteBounds.height - button.frame.height * 0.75)
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor(red: 69/255, green: 182/255, blue: 73/255, alpha: 1.0)
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.applyShadow(radius: 5, opacity: 0.4, height: 2.5, shouldRasterize: false)
        return button
    }()
    
    lazy var captionButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.5, y: button.frame.height * 0.5)
        button.setImage(UIImage(named: "type"), for: .normal)
        button.tintColor = UIColor.white
        button.clipsToBounds = true
        button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        globalMainRef = self
        let screenBounds = UIScreen.main.bounds
        view.backgroundColor = UIColor.black
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        recordBtn = CameraButton(frame: CGRect(x: 0, y: 0, width: 112, height: 112))
        cameraBtnFrame = recordBtn.frame
        cameraBtnFrame.origin.y = screenBounds.height - 140
        cameraBtnFrame.origin.x = self.view.bounds.width/2 - cameraBtnFrame.size.width/2
        recordBtn.frame = cameraBtnFrame
        cameraCenter = recordBtn.center
        recordBtn.applyShadow(radius: 0.67, opacity: 0.67, height: 0.0, shouldRasterize: false)

        cameraView = CameraViewController()
        cameraView.recordBtnRef = recordBtn
        cameraView.delegate = self
        cameraView.view.frame = self.view.bounds
        self.addChildViewController(cameraView)
        view.addSubview(cameraView.view)
        cameraView.didMove(toParentViewController: self)
        
        recordBtn.tappedHandler = recordButtonTapped
        recordBtn.pressedHandler = cameraView.pressed
        
        let buttonSize:CGFloat = 44.0
        
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
        locationHeader.isHidden = true
        
        let locationHeaderTap = UITapGestureRecognizer(target: self, action: #selector(locationHeaderTapped))
        locationHeader.addGestureRecognizer(locationHeaderTap)
        
        let mapViewController  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        mapViewController.view.frame = view.bounds
        
        let v1  = UIViewController()
        v1.view.backgroundColor = UIColor.clear
        v1.view.frame = view.bounds
        
        let v2  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
        v2.view.backgroundColor = UIColor.clear
        v2.view.frame = view.bounds
        
        
        let nav1 = v2.viewControllers![0] as! UINavigationController
        places = nav1.viewControllers[0] as! PlacesViewController
        
        let nav5 = v2.viewControllers![4] as! UINavigationController
        profile = nav5.viewControllers[0] as! MyProfileViewController
        
        var v1Frame: CGRect = CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height)
        v1Frame.origin.y = screenBounds.height
        v1.view.frame = v1Frame
        
        var v2Frame: CGRect = CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height - 20.0)
        v2Frame.origin.y = screenBounds.height * 2 + 20.0
        v2.view.frame = v2Frame
        
        
        scrollView = UIScrollView(frame: view.bounds)
        
        self.addChildViewController(mapViewController)
        self.scrollView.addSubview(mapViewController.view)
        mapViewController.didMove(toParentViewController: self)
        
        self.addChildViewController(v1)
        self.scrollView.addSubview(v1.view)
        v1.didMove(toParentViewController: self)
        
        self.addChildViewController(v2)
        self.scrollView.addSubview(v2.view)
        v2.didMove(toParentViewController: self)
        
        self.scrollView.contentSize = CGSize(width: screenBounds.width, height: screenBounds.height * 3)
        self.scrollView.isPagingEnabled = true
        self.scrollView.bounces = false
        self.scrollView.delegate = self
        self.scrollView.showsVerticalScrollIndicator = false
        

        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.black
        flashView.alpha = 0.0
        
        let height = view.frame.height - cameraBtnFrame.origin.y  + 60 + 60.0
        
        mapContainer = UIView(frame: CGRect(x: 8, y: 20 + 4, width: view.frame.width / 3, height: view.frame.width / 4))
        mapContainer.clipsToBounds = true
        let gradient = CAGradientLayer()
        
        gradient.frame = mapContainer.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.45]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        //mapContainer.layer.mask = gradient
        
        //view.addSubview(mapContainer)
        view.addSubview(flashView)
        view.addSubview(scrollView)
        view.addSubview(flashButton)
        view.addSubview(switchButton)
        view.addSubview(locationHeader)
        view.addSubview(recordBtn)
        
        self.scrollView.setContentOffset(CGPoint(x: 0, y: screenBounds.height), animated: false)
        setToCameraMode()
        
        if gps_service == nil {
            gps_service = GPSService(["MapViewController":mapViewController])
            gps_service.startUpdatingLocation()
            
            places.gps_service = gps_service
        }
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
        //self.navigationController?.navigationBar.isUserInteractionEnabled = false
        
        //NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
       // NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name:NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        if cameraView.cameraState == .PhotoTaken || cameraView.cameraState == .VideoTaken {
            statusBar(hide: true, animated: true)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        returningPlacesCell?.fadeInInfo(animated: true)
        returningPlacesCell = nil
        returningStoriesCell?.activateCell(true)
        returningStoriesCell = nil
        if cameraView.cameraState == .PhotoTaken || cameraView.cameraState == .VideoTaken {
           //statusBar(hide: true, animated: false)
        } else {
            statusBar(hide: false, animated: true)
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            recordBtn.transform = CGAffineTransform(scaleX: 0.5 + 0.2 * multiple, y: 0.5 + 0.2 * multiple)
            recordBtn.ring.layer.borderColor = UIColor.white.cgColor
            recordBtn.ring.backgroundColor = UIColor(white: 1.0, alpha: 0)
            flashButton.center = CGPoint(x: cameraBtnFrame.origin.x / 2 + flashButton.frame.width * reverseAlpha, y: flashButton.center.y)
            flashButton.alpha = multiple
            switchButton.center = CGPoint(x: view.frame.width - cameraBtnFrame.origin.x / 2 - switchButton.frame.width * reverseAlpha, y: switchButton.center.y)
            switchButton.alpha = multiple
            
            locationHeader.alpha = multiple
            locationHeader.center = CGPoint(x: locationHeader.center.x, y: 20 + 22 - (locationHeader.frame.height * 2.0 * reverseAlpha))
        } else if y > height && y <= height * 2.0 {
            let alpha = (y - height) / height
            let reverseAlpha = 1 - alpha
            recordBtn.center = CGPoint(x: cameraCenter.x, y: cameraCenter.y + cameraBtnFrame.height * 0.75 * alpha)
            let multiple = reverseAlpha * reverseAlpha * reverseAlpha * reverseAlpha * reverseAlpha
            let color = UIColor(hue: 97/360, saturation: (1 - multiple) * 0.60, brightness: 0.78, alpha: 1.0)
                //UIColor(hue: 149/360, saturation: 1 - multiple, brightness: 0.88, alpha: 1.0)
            recordBtn.transform = CGAffineTransform(scaleX: 0.5 + 0.2 * multiple, y: 0.5 + 0.2 * multiple)
            recordBtn.ring.layer.borderColor = color.cgColor
            recordBtn.ring.backgroundColor = UIColor(white: 1.0, alpha: 1 - multiple)
            flashView.alpha = alpha
            flashButton.alpha = multiple
            switchButton.alpha = multiple
            locationHeader.alpha = multiple
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y
        if y >= height && y < 10.0 + height {
            print("SET TO CAMERA MODE")
            setToCameraMode()
        } else if y >= height * 2.0 {
            print("SET TO CAMERA HIDDEN")
            screenMode = .Main
        } else {
            print("SET TO MAP")
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
    
    func presentPlaceStory(locationStories:[LocationStory], destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        storyType = .PlaceStory
        
        let storiesViewController: StoriesViewController = StoriesViewController()
        storiesViewController.storyType = storyType
        storiesViewController.locationStories = locationStories
        
        transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject,
                                         "initialIndexPath": initialIndexPath as AnyObject]
        
        storiesViewController.transitionController = transitionController
        
        nav.delegate = transitionController
        transitionController.push(viewController: storiesViewController, on: self, attached: storiesViewController)

    }
    
    func presentUserStory(stories:[UserStory], destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        storyType = .UserStory
        print("PRESENT USER STORY")
        let storiesViewController: StoriesViewController = StoriesViewController()
        storiesViewController.storyType = storyType
        storiesViewController.userStories = stories
        
        transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject,
                                         "initialIndexPath": initialIndexPath as AnyObject]
        
        storiesViewController.transitionController = transitionController
        
        nav.delegate = transitionController
        transitionController.push(viewController: storiesViewController, on: self, attached: storiesViewController)
    }
    
    func presentProfileStory(posts:[StoryItem], destinationIndexPath:IndexPath, initialIndexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        storyType = .ProfileStory
        print("PRESENT PROFILE STORY")
        let galleryViewController: GalleryViewController = GalleryViewController()
        galleryViewController.uid = mainStore.state.userState.uid
        galleryViewController.posts = posts
        galleryViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": destinationIndexPath as AnyObject, "initialIndexPath": initialIndexPath as AnyObject]
        
        nav.delegate = transitionController
        transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
    }
    
}

extension MainViewController: CameraDelegate {
    func takingVideo() {
        UIView.animate(withDuration: 0.42, animations: {
            self.mapContainer?.alpha = 0.0
        })
    }
    
    func takingPhoto() {
        self.mapContainer?.alpha = 0.0
        self.mapContainer?.isUserInteractionEnabled = false
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
        UIView.animate(withDuration: 0.15, animations: {
            self.mapContainer?.alpha = 0.6
            
        })
    }
    
    func hideCameraOptions() {
        scrollView?.isUserInteractionEnabled = false
        flashButton?.isHidden = true
        switchButton?.isHidden = true
        locationHeader?.isHidden = true
        self.mapContainer?.isUserInteractionEnabled = false
        
    }
    
    func showEditOptions() {
        statusBarShouldHide = true
        self.setNeedsStatusBarAppearanceUpdate()
        self.view.addSubview(cancelButton)
        self.view.addSubview(sendButton)
        self.view.addSubview(captionButton)
        
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        //uploadCoordinate = GPSService.sharedInstance.lastLocation!
        uploadLikelihoods = gps_service.getLikelihoods()
    
    }
    
    
    
    func hideEditOptions() {
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        captionButton.removeFromSuperview()
        
        cancelButton.removeTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.removeTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        uploadLikelihoods = []
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func recordButtonTapped() {
        print("RECORD TAPPED: \(screenMode)")
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
            break
        }
    }
    
    func sendButtonTapped(sender: UIButton) {
        
        let upload = Upload()
        if cameraView.cameraState == .PhotoTaken {
            upload.image = cameraView.imageCaptureView.image!
        } else if cameraView.cameraState == .VideoTaken {
            upload.videoURL = cameraView.videoUrl
        }
        
        let nav = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "SendNavigationController") as! UINavigationController
        let controller = nav.viewControllers[0] as! SendViewController
        controller.gps_service = gps_service
        controller.upload = upload
        controller.containerRef = self
        controller.likelihoods = uploadLikelihoods
        
        self.present(nav, animated: false, completion: nil)
        
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
        
        if storyType == .PlaceStory {
            guard let cell: PhotoCell = places.collectionView!.cellForItem(at: i)! as? PhotoCell else { return CGRect.zero }
            let image_frame = cell.imageView.frame
            let x = cell.frame.origin.x + 1
            let navHeight = self.navigationController!.navigationBar.frame.height + 20.0
            let y = cell.frame.origin.y + navHeight - places.collectionView!.contentOffset.y//+ navHeight
            let rect = CGRect(x: x, y: y, width: image_frame.width, height: image_frame.height)// CGRectMake(x,y,image_height, image_height)
            return view.convert(rect, to: view)
        } else if storyType == .UserStory {
            guard let headerCollectionView = places.getHeader()?.collectionView else { return CGRect.zero }
            guard let cell = headerCollectionView.cellForItem(at: indexPath) as? UserStoryCollectionViewCell else { return CGRect.zero }
            let convertedFrame = cell.imageContainer.convert(cell.imageContainer.frame, to: self.view)
            let image_frame = convertedFrame
            let x = cell.frame.origin.x + 10.0 - headerCollectionView.contentOffset.x
            let navHeight = self.navigationController!.navigationBar.frame.height + 20.0
            let y = cell.frame.origin.y + navHeight - places.collectionView!.contentOffset.y + 9.0//+ navHeight
            let rect = CGRect(x: x, y: y, width: image_frame.width, height: image_frame.height)// CGRectMake(x,y,image_height, image_height)
            return view.convert(rect, to: view)
        } else {
            let cell: PhotoCell = profile.collectionView!.cellForItem(at: i)! as! PhotoCell
            let image_frame = cell.imageView.frame
            let x = cell.frame.origin.x + 1
            let navHeight = self.navigationController!.navigationBar.frame.height + 20.0
            let y = cell.frame.origin.y + navHeight - profile.collectionView!.contentOffset.y//+ navHeight
            let rect = CGRect(x: x, y: y, width: image_frame.width, height: image_frame.height)// CGRectMake(x,y,image_height, image_height)
            return view.convert(rect, to: view)
        }
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        if storyType == .PlaceStory {
            guard let cell: PhotoCell = places.collectionView!.cellForItem(at: i) as? PhotoCell else {
                return UIView()
            }
            return cell.imageView
        } else if storyType == .UserStory {
            guard let cell = places.getHeader()?.collectionView.cellForItem(at: indexPath) as? UserStoryCollectionViewCell else {
                return UIView()
            }
            cell.imageContainer.layer.cornerRadius = 0
            cell.imageContainer.layer.borderColor = UIColor.clear.cgColor
            cell.imageContainer.clipsToBounds = false
            return cell.imageContainer
        } else {
            let cell: PhotoCell = profile.collectionView!.cellForItem(at: i) as! PhotoCell
            return cell.imageView
        }
        
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        print("PREP")
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        
        if isPresenting {
            if storyType == .UserStory {
                if let cell = places.getHeader()?.collectionView.cellForItem(at: i) as? UserStoryCollectionViewCell {
                    returningStoriesCell = cell
                }
            }
        }
        
        if !isPresenting {
            if storyType == .PlaceStory {
                if let cell = places.collectionView!.cellForItem(at: indexPath) as? PhotoCell {
                    returningPlacesCell?.fadeInInfo(animated: false)
                    returningPlacesCell = cell
                    returningPlacesCell!.fadeOutInfo()
                }
            } else if storyType == .UserStory {
                if let cell = places.getHeader()?.collectionView.cellForItem(at: i) as? UserStoryCollectionViewCell {

                    returningStoriesCell?.activateCell(false)
            
                    returningStoriesCell = cell
                }
            } else {
                
            }
        }
        if storyType == .PlaceStory {
            if !isPresenting && !places.collectionView!.indexPathsForVisibleItems.contains(indexPath) {
                places.collectionView!.reloadData()
                places.collectionView!.scrollToItem(at: i, at: .centeredVertically, animated: false)
                places.collectionView!.layoutIfNeeded()
            }
        }
        
        if storyType == .ProfileStory {
            if !isPresenting && !profile.collectionView!.indexPathsForVisibleItems.contains(indexPath) {
                profile.collectionView!.reloadData()
                profile.collectionView!.scrollToItem(at: i, at: .centeredVertically, animated: false)
                profile.collectionView!.layoutIfNeeded()
            }
        }
    }
    
    func dismissInteractionEnded(_ completed: Bool) {
        
        //        if completed {
        //            statusBarShouldHide = false
        //            self.setNeedsStatusBarAppearanceUpdate()
        //        }
        
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
    case PlaceStory, UserStory, ProfileStory
}
