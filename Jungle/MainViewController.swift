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

var globalMainRef:MainViewController?

class MainViewController: UIViewController, UIScrollViewDelegate {

    
    var scrollView:UIScrollView!
    
    var cameraView:CameraViewController!
    var recordBtn:CameraButton!
    var cameraBtnFrame:CGRect!
    
    var places:PlacesViewController!
    
    var returningPlacesCell:PhotoCell?
    var flashView:UIView!
    
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
        recordBtn.applyShadow(radius: 0.67, opacity: 0.67, height: 0.0, shouldRasterize: false)

        
        cameraView = CameraViewController()
        cameraView.recordBtnRef = recordBtn
        cameraView.view.frame = self.view.bounds
        self.addChildViewController(cameraView)
        view.addSubview(cameraView.view)
        cameraView.didMove(toParentViewController: self)
        
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
        recordBtn.removeGestures()
        let height = UIScreen.main.bounds.height
        let y = scrollView.contentOffset.y
        if y < height {
            let alpha = y / height
            
            var recordBtnFrame = cameraBtnFrame
            recordBtnFrame!.origin.y = cameraBtnFrame.origin.y + cameraBtnFrame.height * 0.72 * alpha
            recordBtn.frame = recordBtnFrame!
            recordBtn.dot.alpha = 1 - alpha
            
            let color = UIColor(hue: 0.6, saturation: alpha, brightness: 1.0, alpha: 1.0)
            recordBtn.ring.layer.borderColor = color.cgColor
            flashView.alpha = alpha

            
        } else if y > height {
            let alpha = (y - height) / height
            
            var recordBtnFrame = cameraBtnFrame
            recordBtnFrame!.origin.y = cameraBtnFrame.origin.y + cameraBtnFrame.height * 0.72 * alpha
            recordBtn.frame = recordBtnFrame!
            recordBtn.dot.alpha = 1 - alpha
            flashView.alpha = alpha

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
//        if mapView == nil {
//            
//            let camera = GMSCameraPosition.camera(withTarget: currentLocation.coordinate, zoom: 16.5)
//            
//            mapView = GMSMapView.map(withFrame: mapContainer.bounds, camera: camera)
//            mapContainer.addSubview(mapView!)
//            mapView!.backgroundColor = UIColor.black
//            mapView!.isMyLocationEnabled = false
//            mapView!.settings.scrollGestures = false
//            mapView!.settings.rotateGestures = false
//            mapView!.settings.tiltGestures = false
//            mapView!.isUserInteractionEnabled = false
//            mapView!.isBuildingsEnabled = true
//            mapView!.isIndoorEnabled = true
//            mapContainer.alpha = 0.75
//            
//            do {
//                // Set the map style by passing the URL of the local file.
//                if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
//                    mapView!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
//                } else {
//                    NSLog("Unable to find style.json")
//                }
//            } catch {
//                NSLog("One or more of the map styles failed to load. \(error)")
//            }
//            
//        } else{
//            mapView!.animate(toLocation: currentLocation.coordinate)
//        }
    }
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        print(error.code)
        
        
    }
}
