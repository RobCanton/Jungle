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

    var scrollView:UIScrollView!
    
    var cameraView:CameraViewController!
    var recordBtn:CameraButton!
    var cameraBtnFrame:CGRect!
    var cameraCenter:CGPoint!
    
    var places:PlacesViewController!
    
    var returningPlacesCell:PhotoCell?
    var flashView:UIView!
    
    var uploadCoordinate:CLLocation?
    
    var flashButton:UIButton!
    var switchButton:UIButton!
    
    var mapView:GMSMapView?
    var mapContainer:UIView!
    
    var screenMode:ScreenMode = .Camera
    
    lazy var cancelButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.center = CGPoint(x: button.frame.width * 0.60, y: definiteBounds.height - button.frame.height * 0.60)
        button.tintColor = UIColor.white
        //button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
        
    }()
    
    lazy var sendButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.setImage(UIImage(named: "right_arrow"), for: .normal)
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.75, y: definiteBounds.height - button.frame.height * 0.75)
        button.tintColor = UIColor.black
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        //button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
    }()
    
    lazy var captionButton: UIButton = {
        let definiteBounds = UIScreen.main.bounds
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        button.center = CGPoint(x: definiteBounds.width - button.frame.width * 0.5, y: button.frame.height * 0.5)
        button.setImage(UIImage(named: "type"), for: .normal)
        button.tintColor = UIColor.white
        button.clipsToBounds = true
        //button.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        globalMainRef = self
        let definiteBounds = UIScreen.main.bounds
        view.backgroundColor = UIColor.black
        
        recordBtn = CameraButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        cameraBtnFrame = recordBtn.frame
        cameraBtnFrame.origin.y = definiteBounds.height - 140
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
        
        var v1  = UIViewController()
        v1.view.backgroundColor = UIColor.clear
        v1.view.frame = view.bounds
        
        var v2  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
        v2.view.backgroundColor = UIColor.clear
        v2.view.frame = view.bounds
        
        let nav1 = v2.viewControllers![0] as! UINavigationController
        places = nav1.viewControllers[0] as! PlacesViewController
        
        var v2Frame: CGRect = CGRect(x: 0, y: 0, width: definiteBounds.width, height: definiteBounds.height - 20.0)
        v2Frame.origin.y = definiteBounds.height + 20.0
        v2.view.frame = v2Frame
        
        
        scrollView = UIScrollView(frame: view.bounds)
        
        self.addChildViewController(v1)
        self.scrollView.addSubview(v1.view)
        v1.didMove(toParentViewController: self)
        
        self.addChildViewController(v2)
        self.scrollView.addSubview(v2.view)
        v2.didMove(toParentViewController: self)
        
        self.scrollView.contentSize = CGSize(width: definiteBounds.width, height: definiteBounds.height * 2)
        self.scrollView.isPagingEnabled = true
        self.scrollView.bounces = false
        self.scrollView.delegate = self
        self.scrollView.showsVerticalScrollIndicator = false
        
        
        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.black
        flashView.alpha = 0.0
        
        let height = view.frame.height - cameraBtnFrame.origin.y  + 60
        
        mapContainer = UIView(frame: CGRect(x: 0, y: view.frame.height - height, width: view.frame.width, height: height))
        mapContainer.clipsToBounds = true
        let gradient = CAGradientLayer()
        
        gradient.frame = mapContainer.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        mapContainer.layer.mask = gradient
        
        view.addSubview(mapContainer)
        view.addSubview(flashView)
        view.addSubview(scrollView)
        view.addSubview(recordBtn)
        
        GPSService.sharedInstance.delegate = self
        GPSService.sharedInstance.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        returningPlacesCell?.fadeInInfo(animated: true)
        returningPlacesCell = nil
        statusBar(hide: false, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        screenMode = .Transitioning
        recordBtn.removeGestures()
        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y
        if y < height {
            let alpha = y / height
            let reverseAlpha = 1 - alpha
            
            let color = UIColor(hue: 0.6, saturation: alpha, brightness: 1.0, alpha: 1.0)
            recordBtn.ring.layer.borderColor = color.cgColor
            recordBtn.ring.backgroundColor = UIColor(white: 1.0, alpha: alpha)
            recordBtn.transform = CGAffineTransform(scaleX: 0.8 + 0.2 * reverseAlpha, y: 0.8 + 0.2 * reverseAlpha)
            recordBtn.center = CGPoint(x: cameraCenter.x, y: cameraCenter.y + cameraBtnFrame.height * 0.75 * alpha)
            flashView.alpha = alpha
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y
        if y == 0 {
            screenMode = .Camera
        } else if y >= height {
            screenMode = .CameraHidden
        }
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
            if statusBarIsLight {
                return .lightContent
            } else {
                return .default
            }
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
    }
    
    func showCameraOptions() {
        //scrollView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.15, animations: {
            self.mapContainer?.alpha = 0.75
        })
    }
    
    func hideCameraOptions() {
        //scrollView.isUserInteractionEnabled = false
        self.mapContainer?.isUserInteractionEnabled = false
        
    }
    
    func showEditOptions() {
        self.view.addSubview(cancelButton)
        self.view.addSubview(sendButton)
        self.view.addSubview(captionButton)
        
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        uploadCoordinate = GPSService.sharedInstance.lastLocation!
        
        statusBarShouldHide = true
        self.setNeedsStatusBarAppearanceUpdate()
        
    }
    
    func hideEditOptions() {
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        captionButton.removeFromSuperview()
        
        cancelButton.removeTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.removeTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        uploadCoordinate = nil
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func recordButtonTapped() {
        print("RECORD TAPPED")
        switch screenMode {
        case .Camera:
            cameraView.didPressTakePhoto()
            break
        case .CameraHidden:
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
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
        controller.upload = upload
        controller.containerRef = self
        
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
    
}

extension MainViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath else {
            return CGRect.zero
        }
        
        let i =  IndexPath(row: indexPath.item, section: 0)
        let cell: PhotoCell = places.collectionView!.cellForItem(at: i)! as! PhotoCell
        let image_frame = cell.imageView.frame
        let x = cell.frame.origin.x + 1
        let navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        let y = cell.frame.origin.y + navHeight - places.collectionView!.contentOffset.y//+ navHeight
        let rect = CGRect(x: x, y: y, width: image_frame.width, height: image_frame.height)// CGRectMake(x,y,image_height, image_height)
        return view.convert(rect, to: view)
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        let cell: PhotoCell = places.collectionView!.cellForItem(at: i) as! PhotoCell
        print("INITIAL VIEW")
        return cell.imageView
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        print("PREP")
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let i = IndexPath(row: indexPath.item, section: 0)
        
        if !isPresenting {
            if let cell = places.collectionView!.cellForItem(at: indexPath) as? PhotoCell {
                returningPlacesCell?.fadeInInfo(animated: false)
                returningPlacesCell = cell
                returningPlacesCell!.fadeOutInfo()
            }
        }
        
        if !isPresenting && !places.collectionView!.indexPathsForVisibleItems.contains(indexPath) {
            places.collectionView!.reloadData()
            places.collectionView!.scrollToItem(at: i, at: .centeredVertically, animated: false)
            places.collectionView!.layoutIfNeeded()
        }
    }
    
    func dismissInteractionEnded(_ completed: Bool) {
        
        //        if completed {
        //            statusBarShouldHide = false
        //            self.setNeedsStatusBarAppearanceUpdate()
        //        }
        
    }
    
}

extension MainViewController: GPSServiceDelegate {
    func tracingLocation(_ currentLocation: CLLocation) {
        print("New location")
        LocationService.sharedInstance.requestNearbyLocations(currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        // singleton for get last location
        if mapView == nil {
            
            let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 16.5)
            
            mapView = GMSMapView.map(withFrame: mapContainer.bounds, camera: camera)
            mapContainer.addSubview(mapView!)
            mapView!.backgroundColor = UIColor.black
            mapView!.isMyLocationEnabled = false
            mapView!.settings.scrollGestures = false
            mapView!.settings.rotateGestures = false
            mapView!.settings.tiltGestures = false
            mapView!.isUserInteractionEnabled = false
            mapView!.isBuildingsEnabled = true
            mapView!.isIndoorEnabled = true
            mapView!.alpha = 0.0
            
            UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseIn, animations: {
                self.mapView!.alpha = 0.7
            }, completion: nil)
            
            do {
                // Set the map style by passing the URL of the local file.
                if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
                    mapView!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } else {
                    NSLog("Unable to find style.json")
                }
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
            
        } else{
            mapView!.animate(toLocation: currentLocation.coordinate)
        }
    }
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        print(error.code)
        
        
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
    case Transitioning, Camera, CameraHidden
}
