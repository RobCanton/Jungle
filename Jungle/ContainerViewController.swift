//
//  ContainerViewController.swift
//  Riot
//
//  Created by Robert Canton on 2017-03-13.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import AVFoundation
import Firebase



protocol CameraDelegate {
    func showCameraOptions()
    func hideCameraOptions()
    func showEditOptions()
    func hideEditOptions()
    func takingPhoto()
    func takingVideo()
}

var globalContainerRef:ContainerViewController?

class ContainerViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var screenMode:ScreenMode = .Camera

    var placesClient: GMSPlacesClient!
    
    var recordBtn:CameraButton!
    var mapView:GMSMapView?
    var mapContainer:UIView!
    
    var flashView:UIView!
    
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
    
    var uploadCoordinate:CLLocation?
    
    var flashButton:UIButton!
    var switchButton:UIButton!
    
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var v1: PlacesViewController!
    var v2: ActivityViewController!
    var v3: UIViewController!
    var cameraView:CameraViewController!
    
    var cameraBtnFrame:CGRect!
    
    var snapContainer:SnapContainerViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let definiteBounds = UIScreen.main.bounds
        view.backgroundColor = UIColor.black
        globalContainerRef = self
        
        recordBtn = CameraButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        cameraBtnFrame = recordBtn.frame
        cameraBtnFrame.origin.y = definiteBounds.height - 140
        cameraBtnFrame.origin.x = self.view.bounds.width/2 - cameraBtnFrame.size.width/2
        recordBtn.frame = cameraBtnFrame
        
        cameraView = CameraViewController()
        cameraView.recordBtnRef = recordBtn
        cameraView.delegate = self
        cameraView.view.frame = self.view.bounds
        self.addChildViewController(cameraView)
        
        cameraView.didMove(toParentViewController: self)
        
        
        recordBtn.tappedHandler = recordButtonTapped
        recordBtn.pressedHandler = cameraView.pressed
        recordBtn.applyShadow(radius: 0.5, opacity: 0.75, height: 0.0, shouldRasterize: false)
        
        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0
        self.view.insertSubview(flashView, belowSubview: recordBtn)
        
        placesClient = GMSPlacesClient.shared()
        
        let height = view.frame.height - cameraBtnFrame.origin.y  + 60
        
        mapContainer = UIView(frame: CGRect(x: 0, y: view.frame.height - height, width: view.frame.width, height: height))
        //mapContainer.layer.cornerRadius = 56
        mapContainer.clipsToBounds = true
        
        let gradient = CAGradientLayer()
        
        gradient.frame = mapContainer.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        mapContainer.layer.mask = gradient
    

        v1 = PlacesViewController()
        
        let nav = UINavigationController(rootViewController: v1)

        nav.view.frame = self.view.bounds
        v1.masterNav = self.navigationController
        v1.container = self
        
        v2 = ActivityViewController()
        let nav2 = UINavigationController(rootViewController: v2)
        v2.view.backgroundColor = UIColor.white
        v2.view.frame = v1.view.bounds
        
        /*
        v3 = UIViewController()
        v3.view.backgroundColor = UIColor.white
        v3.view.frame = v1.view.bounds
        
        self.addChildViewController(nav)
        self.scrollView.addSubview(nav.view)
        nav.didMove(toParentViewController: self)
        
        self.addChildViewController(v2)
        self.scrollView.addSubview(v2.view)
        v2.didMove(toParentViewController: self)
        
        self.addChildViewController(v3)
        self.scrollView.addSubview(v3.view)
        v3.didMove(toParentViewController: self)
        
        var v2Frame: CGRect = v2.view.frame
        v2Frame.origin.x = self.view.frame.width
        v2.view.frame = v2Frame
        
        var v3Frame: CGRect = v3.view.frame
        v3Frame.origin.x = self.view.frame.width * 2
        v3.view.frame = v3Frame
        
        self.scrollView.contentSize = CGSize(width: self.view.frame.width * 3, height: self.view.frame.size.height)
        self.scrollView.isPagingEnabled = true
        self.scrollView.bounces = false
        
        self.scrollView.setContentOffset(CGPoint(x:v2Frame.origin.x,y: 0), animated: false)
        
        var userVC = UIViewController()
        userVC.view.frame = v1.view.bounds
        userVC.view.backgroundColor = UIColor.green
        
        var clearVC = UIViewController()
        clearVC.view.frame = v1.view.bounds
        clearVC.view.backgroundColor = UIColor.red
        
        self.addChildViewController(userVC)
        self.verticalScrollView.addSubview(userVC.view)
        userVC.didMove(toParentViewController: self)
        
        self.addChildViewController(clearVC)
        self.verticalScrollView.addSubview(clearVC.view)
        clearVC.didMove(toParentViewController: self)
        
        self.verticalScrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.size.height * 2)
        self.verticalScrollView.isPagingEnabled = true
        self.verticalScrollView.bounces = false
        
        self.verticalScrollView.setContentOffset(CGPoint(x:0,y: v1.view.frame.height), animated: false)
        
        */
        
        let middle = UIViewController()
        middle.view.frame = self.view.frame
        middle.view.backgroundColor = UIColor.clear
        let right = UIViewController()
        right.view.frame = self.view.frame
        right.view.backgroundColor = UIColor.yellow
        let top = UIViewController()
        top.view.frame = self.view.frame
        top.view.backgroundColor = UIColor.blue
        let bottom = UIViewController()
        bottom.view.frame = self.view.frame
        bottom.view.backgroundColor = UIColor.red
        snapContainer = SnapContainerViewController.containerViewWith(nav,
                                                                          middleVC: middle,
                                                                          rightVC: nav2,
                                                                          topVC: top,
                                                                          bottomVC: bottom)
        self.addChildViewController(snapContainer)
        snapContainer.didMove(toParentViewController: self)
        
        self.view.addSubview(cameraView.view)
        self.view.addSubview(mapContainer)
        self.view.addSubview(flashView)
        self.view.addSubview(snapContainer.view)
        self.view.addSubview(recordBtn)
        
        GPSService.sharedInstance.delegate = self
        GPSService.sharedInstance.startUpdatingLocation()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func recordButtonTapped() {
        print("RECORD TAPPED")
        switch screenMode {
        case .Transitioning:
            break
        case .Activity:
            //scrollView.setContentOffset(CGPoint(x:v2.view.frame.origin.x, y: 0), animated: true)
            break
        case .Camera:
            
            print("CAMERA")
            cameraView.didPressTakePhoto()
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

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        

    }
    
    func hideOverlay() {
        self.recordBtn.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.15, animations: {
            self.recordBtn.alpha = 0.0
        })
    }
    
    func showOverlay() {
        self.recordBtn.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.15, animations: {
            self.recordBtn.alpha = 1.0
        }, completion: { success in
            self.recordBtn.isUserInteractionEnabled = true
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        screenMode = .Transitioning
//        recordBtn.removeGestures()
//        let v2Start = v2.view.frame.origin.x
//        let x = scrollView.contentOffset.x
//        if x < v2.view.frame.origin.x {
//            let alpha = 1 - x / v2Start
//            
//            var recordBtnFrame = cameraBtnFrame
//            recordBtnFrame!.origin.y = cameraBtnFrame.origin.y + cameraBtnFrame.height / 2 * alpha
//            recordBtn.frame = recordBtnFrame!
//            recordBtn.alpha = 0.5 + 0.5 * (1 - alpha)
//            recordBtn.dot.alpha = 1 - alpha
//            
//        }
//    }
//    
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("STOPPED: \(scrollView.contentOffset.x)")
//        let x = scrollView.contentOffset.x
//        if x == 0 {
//            print("ACTIVITY ACTIVE")
//            screenMode = .Activity
//        } else if x == v2.view.frame.origin.x {
//            screenMode = .Camera
//            recordBtn.addGestures()
//        } else if x == v3.view.frame.origin.x {
//            print("FOLLOWING ACTIVE")
//            
//        }
//    }
    
    var statusBarShouldHide = false
//    
    override var prefersStatusBarHidden: Bool {
        get {
            return statusBarShouldHide
        }
    }
    
    public func statusBar(hide: Bool) {
        statusBarShouldHide = hide
        self.setNeedsStatusBarAppearanceUpdate()
    }

    
    
}


extension ContainerViewController: CameraDelegate {
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
        
    }
    
    func hideEditOptions() {
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        captionButton.removeFromSuperview()
        
        cancelButton.removeTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        sendButton.removeTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        uploadCoordinate = nil
    }
    

}



extension ContainerViewController: GPSServiceDelegate {
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
            mapContainer.alpha = 0.75
            
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
    case Transitioning, Camera, Activity
}
