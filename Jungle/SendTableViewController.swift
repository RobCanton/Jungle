//
//  SendTableViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-10.
//  Copyright © 2017 Robert Canton. All rights reserved.
//
import UIKit
import GoogleMaps
import GooglePlaces

class SendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let subscriberName = "SendViewController"
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var sendLabel: UILabel!
    
    var placesClient: GMSPlacesClient!
    
    var likelihoods = [GMSPlaceLikelihood]()
    var upload:Upload!
    
    var sendTap:UITapGestureRecognizer!
    
    var headerView:UIView!
    
    var mapView:GMSMapView?
    var gps_service: GPSService!
    var cameraViewRef:CameraViewController?
    var navHeight:CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.black
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        self.addNavigationBarBackdrop()
        title = "Post To..."
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightSemibold)]
        self.navigationController?.navigationBar.tintColor = accentColor
        sendView.backgroundColor = UIColor.clear
        
        let gradient = CAGradientLayer()
        gradient.frame = sendView.bounds
        gradient.colors = [
            lightAccentColor.cgColor,
            darkAccentColor.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        sendView.layer.insertSublayer(gradient, at: 0)
        
        let nib = UINib(nibName: "SendProfileViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "profileCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        headerView  = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 275 + navHeight))
        
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        
        sendTap = UITapGestureRecognizer(target: self, action: #selector(send))
        sendView.isUserInteractionEnabled = true
        sendView.addGestureRecognizer(sendTap)
        
        if let location = gps_service.getLastLocation() {
            setupMapView(withLocation: location)
        }
        
        self.tableView.reloadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(false, animated: true)
        gps_service.subscribe(subscriberName, subscriber: self)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gps_service.unsubscribe(subscriberName)
    }
    @IBAction func handleBack(_ sender: Any) {
        //self.dismiss(animated: false, completion: nil)
    }
    
    func setupMapView(withLocation location:CLLocation) {
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 18.0)
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: navHeight, width: headerView.bounds.width, height: headerView.bounds.height - navHeight), camera: camera)
        headerView.addSubview(mapView!)
        mapView!.backgroundColor = UIColor.black
        mapView!.isMyLocationEnabled = true
        mapView!.settings.scrollGestures = false
        mapView!.settings.rotateGestures = true
        mapView!.settings.tiltGestures = false
        mapView!.isBuildingsEnabled = true
        mapView!.isIndoorEnabled = true
        
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
        
        for likelihood in self.likelihoods {
            let marker = GMSMarker(position: likelihood.place.coordinate)
            marker.title = likelihood.place.name
            marker.map = mapView
        }
    }
    
    func sent() {
        globalMainInterfaceProtocol?.presentHomeScreen(animated: true)
        self.navigationController?.popViewController(animated: false)
    }
    
    
    func send() {
        
        if !mainStore.state.settingsState.uploadWarningShown {
            
            let alert = UIAlertController(title: "Heads up!", message: "All posts on Jungle are public and can be seen by anyone (except for users you have blocked). Don't post anything too personal.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Nevermind", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: { _ in
                mainStore.dispatch(UploadWarningShown())
                UserService.ref.child("users/settings/\(mainStore.state.userState.uid)/upload_warning_shown").setValue(true)
            }))
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.startAnimating()
        activityIndicator.center = sendView.center
        view.addSubview(activityIndicator)
        
        sendLabel.isHidden = true
        
        
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
            
            UploadService.compressVideo(inputURL: videoURL, outputURL: outputUrl, handler: { session in
                DispatchQueue.main.async {
                    UploadService.uploadVideo(upload: self.upload, completion: { success in
                        self.sent()
                    })
                }
            })
            
        } else if upload.image != nil {
            UploadService.sendImage(upload: upload, completion: { success in
                self.sent()
            })
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likelihoods.count
    }
    
    
    
    
    var selectedLocationIndexPath:IndexPath?
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
            as! SendProfileViewCell
        cell.label.text = likelihoods[indexPath.row].place.name
        if let address = likelihoods[indexPath.row].place.formattedAddress {
            cell.subtitle.text = getShortFormattedAddress(address)
        } else {
            cell.subtitle.text = ""
        }
        
        cell.toggleSelection(false)
        return cell
    }
    
    var selectedIndex:IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = likelihoods[indexPath.row].place
        
        let currentCell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
        if currentCell.isActive {
            currentCell.toggleSelection(false)
            selectedIndex =  nil
            upload.place = nil
        } else {
            if let oldPath = selectedIndex {
                let oldCell = tableView.cellForRow(at: oldPath) as! SendProfileViewCell
                oldCell.toggleSelection(false)
            }
            currentCell.toggleSelection(true)
            selectedIndex =  indexPath
            upload.place = place
        }
        
    }
    
}

extension SendViewController: GPSServiceProtocol {
    func tracingLocation(_ currentLocation: CLLocation) {
        //LocationService.sharedInstance.requestNearbyLocations(currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        // singleton for get last location
        if mapView == nil {
            setupMapView(withLocation: currentLocation)
        } else{
            mapView!.animate(toLocation: currentLocation.coordinate)
        }
    }
    
    func significantLocationUpdate(_ location: CLLocation) {}
    
    func nearbyPlacesUpdate(_ likelihoods: [GMSPlaceLikelihood]) {}
    
    func tracingLocationDidFailWithError(_ error: NSError) {}
    
    func horizontalAccuracyUpdated(_ accuracy: Double?) {}
}
