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
    
    var followers = [String]()
    
    var selectedFollowers = [String:Bool]()
    deinit {
        print("Deinit >> SendTableViewController")
    }
    
    var sendGradient:CAGradientLayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        self.addNavigationBarBackdrop()
        title = "Send To"
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightSemibold)]
        sendView.backgroundColor = UIColor.clear
        
        let nib = UINib(nibName: "SendProfileViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "profileCell")
        
        let bannerView = UINib(nibName: "BannerView", bundle: nil)
        tableView.register(bannerView, forHeaderFooterViewReuseIdentifier: "bannerView")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 200 + navHeight))
        
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.separatorColor = UIColor(white: 0.92, alpha: 1.0)

        sendTap = UITapGestureRecognizer(target: self, action: #selector(send))
        sendView.isUserInteractionEnabled = true
        sendView.addGestureRecognizer(sendTap)
        
        setSendEnabled(true)
        
        if let location = gps_service.getLastLocation() {
            setupMapView(withLocation: location)
        }
        
        followers = mainStore.state.socialState.followers.sorted()
        self.tableView.reloadData()
                
    }

    func setSendEnabled(_ enabled:Bool) {
        if enabled {
            if sendGradient != nil { return }
            sendGradient = CAGradientLayer()
            sendGradient!.frame = sendView.bounds
            sendGradient!.colors = [
                lightAccentColor.cgColor,
                darkAccentColor.cgColor
            ]
            sendGradient!.locations = [0.0, 1.0]
            sendGradient!.startPoint = CGPoint(x: 0, y: 0)
            sendGradient!.endPoint = CGPoint(x: 1, y: 0)
            sendView.layer.insertSublayer(sendGradient!, at: 0)
            sendView.isUserInteractionEnabled = true
        } else {
            sendGradient?.removeFromSuperlayer()
            sendGradient = nil
            sendView.isUserInteractionEnabled = false
        }
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
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 19.0)
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
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.startAnimating()
        activityIndicator.center = sendView.center
        view.addSubview(activityIndicator)
        
        sendLabel.isHidden = true
        
        UIView.animate(withDuration: 0.25, animations: {
            self.sendView.alpha = 0
        }, completion: { _ in
            
            DispatchQueue.main.async {
                if let videoURL = self.upload.videoURL {
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
                    self.upload.videoURL = outputUrl
                    
                    UploadService.compressVideo(inputURL: videoURL, outputURL: outputUrl, handler: { session in
                        DispatchQueue.main.async {
                            UploadService.uploadVideo(upload: self.upload, completion: { success in
                                self.sent()
                            })
                        }
                    })
                    
                } else if self.upload.image != nil {
                    UploadService.sendImage(upload: self.upload, completion: { success in
                        self.sent()
                    })
                }
            }
        })
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return likelihoods.count
        case 2:
            return followers.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "bannerView") as! BannerView
        switch section {
        case 0:
            return nil
        case 1:
            view.titleLabel.text = "NEARBY PLACES"
            break
        default:
            view.titleLabel.text = "FOLLOWERS"
            break
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        case 1:
            return likelihoods.count > 0 ? 38 : 0
        case 2:
            return followers.count > 0 ? 38 : 0
        default:
            return 0
        }
    }

    
    var selectedLocationIndexPath:IndexPath?

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! SendProfileViewCell
            cell.setTextBold(true)
            if indexPath.row == 0 {
                cell.label.text = "Your Profile"
                cell.subtitle.text = "Save to your public profile"
                cell.lockState()
            } else if indexPath.row == 1 {
                cell.label.text = "Your Story"
                cell.subtitle.text = "Share with your followers"
                cell.toggleSelection(upload.toStory)
            } else if indexPath.row == 2 {
                cell.label.text = "Nearby"
                cell.subtitle.text = "Share with everyone in your area"
                cell.toggleSelection(upload.toNearby)
            }
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! SendProfileViewCell
            cell.setTextBold(false)
            let place = likelihoods[indexPath.row].place
            cell.label.text = place.name
            if let address = place.formattedAddress {
               cell.subtitle.text = getShortFormattedAddress(address)
            } else {
                cell.subtitle.text = ""
            }
            cell.toggleSelection(false)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
                as! SendProfileViewCell
            cell.setTextBold(false)
            let uid = followers[indexPath.row]
            cell.setupUser(uid: uid)
            cell.toggleSelection(selectedFollowers[uid] != nil)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
            return cell
        }
    }
    
    var selectedIndex:IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                upload.toProfile = !upload.toProfile
                let currentCell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
                currentCell.toggleSelection(upload.toProfile)
                break
            case 1:
                upload.toStory = !upload.toStory
                let currentCell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
                currentCell.toggleSelection(upload.toStory)
                break
            case 2:
                upload.toNearby = !upload.toNearby
                let currentCell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
                currentCell.toggleSelection(upload.toNearby)
                tableView.reloadData()
                break
            default:
                break
            }
            break
        case 1:
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
            if upload.place != nil && !upload.toNearby {
                upload.toNearby = true
                tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
            }
            break
        case 2:
            let cell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
            let uid = followers[indexPath.row]
            
            if selectedFollowers[uid] == nil {
                selectedFollowers[uid] = true
                cell.toggleSelection(true)
            } else {
                selectedFollowers[uid] = nil
                cell.toggleSelection(false)
            }
            upload.recipients = selectedFollowers
            break
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
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
