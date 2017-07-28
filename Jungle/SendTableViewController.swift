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
import Firebase
import Popover

class SendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GMSMapViewDelegate {
    
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
    
    var userButton:UIButton!
    
    var titleLabel:UILabel!
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.black
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        self.addNavigationBarBackdrop()
        title = "Post as @\(userState.user!.username)"
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
        
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 32))
        titleLabel.textColor = accentColor
        titleLabel.text = "Post"
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(switchAnonMode))
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(tap)
        
        userButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        userButton.setImage(nil, for: .normal)
        userButton.cropToCircle()
        userButton.addTarget(self, action: #selector(switchAnonMode), for: .touchUpInside)
        
        
        let barButton = UIBarButtonItem(customView: userButton)
        barButton.action = #selector(switchAnonMode)

        self.navigationItem.rightBarButtonItem = barButton
        
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
        
        sendLabel.text = "My Location"
        self.tableView.reloadData()
        showCurrentAnonMode()
        
    }

    
    func switchAnonMode() {
        mainStore.dispatch(ToggleAnonMode())
        showCurrentAnonMode()
        
        
    }
    
    func showCurrentAnonMode() {
        let isAnon = mainStore.state.userState.anonMode
        if isAnon {
            
            setTitleLabel(prefix: "Post ", username: "anonymously", suffix: " to...")
            userButton.setImage(UIImage(named: "private_dark"), for: .normal)
        } else {
            guard let user = mainStore.state.userState.user else {
                userButton.setImage(nil, for: .normal)
                return
            }
            
            setTitleLabel(prefix: "Post as ", username: "@\(user.username)", suffix: " to...")
            loadImageUsingCacheWithURL(user.imageURL) { image, fromCache in
                self.userButton.setImage(image, for: .normal)
            }
        }
    }
    
    func setTitleLabel(prefix:String, username:String, suffix:String) {
        let str = "\(prefix)\(username)\(suffix)"
        let attributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: accentColor,
            NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        let a: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor.darkGray,
            NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold),
            ]
        title.addAttributes(a, range: NSRange(location: 0, length: prefix.characters.count))
        title.addAttributes(a, range: NSRange(location: prefix.characters.count + username.characters.count, length: suffix.characters.count))
        
        titleLabel.attributedText = title
        
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
        mapView!.delegate = self
        
//        do {
//            // Set the map style by passing the URL of the local file.
//            if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
//                mapView!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
//            } else {
//                NSLog("Unable to find style.json")
//            }
//        } catch {
//            NSLog("One or more of the map styles failed to load. \(error)")
//        }
        
        for likelihood in self.likelihoods {
            let marker = GMSMarker(position: likelihood.place.coordinate)
            marker.title = likelihood.place.name
            marker.map = mapView
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        for i in 0..<self.likelihoods.count {
            let likelihood = likelihoods[i]
            if marker.title == likelihood.place.name {
                let indexPath = IndexPath(row: i, section: 0)
                let place = likelihoods[indexPath.row].place
                
                let currentCell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
                if currentCell.isActive {
                    currentCell.toggleSelection(false)
                    selectedIndex =  nil
                    upload.place = nil
                    sendLabel.text = "My location"
                    if let location = gps_service.getLastLocation() {
                        mapView.animate(toLocation: location.coordinate)
                    }
                    return true
                } else {
                    if let oldPath = selectedIndex {
                        let oldCell = tableView.cellForRow(at: oldPath) as! SendProfileViewCell
                        oldCell.toggleSelection(false)
                    }
                    currentCell.toggleSelection(true)
                    selectedIndex =  indexPath
                    upload.place = place
                    
                    sendLabel.text = place.name
                    mapView.animate(toLocation: place.coordinate)
                }
            }
        }
        
        return false
    }
    
    
    func sent() {
        globalMainInterfaceProtocol?.presentHomeScreen(animated: true)
        self.navigationController?.popViewController(animated: false)
    }
    
    
    func send() {
        
        if !mainStore.state.settingsState.uploadWarningShown {
            
            let alert = UIAlertController(title: "Heads up!", message: "All posts on Jungle are public and can be seen by anyone (except for users you have blocked). Don't post anything too personal.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Nevermind", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in
                mainStore.dispatch(UploadWarningShown())
                UserService.ref.child("users/settings/\(mainStore.state.userState.uid)/upload_warning_shown").setValue(true)
                self.preparePost()
            }))
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        preparePost()
    }
    
    func preparePost() {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.startAnimating()
        activityIndicator.center = sendView.center
        view.addSubview(activityIndicator)
        
        sendLabel.isHidden = true
        
        
        if userState.anonMode {
            
            APIService.getRandomAnonymousInfo() { anonObject, success in
                DispatchQueue.main.async {
                    if success, let anon = anonObject {
                        self.upload.anonObject = anon
                        self.uploadPost()
                    }
                }

            }
        } else {
            
            uploadPost()
        }
        
    }
    
    func uploadPost() {
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
                    UploadService.getUploadKey(upload: self.upload) { success in
                        self.sent()
                    }
                }
            })
            
        } else if upload.image != nil {
            UploadService.getUploadKey(upload: self.upload) { success in
                self.sent()
            }
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return likelihoods.count
    }
    
    
    
    
    var selectedLocationIndexPath:IndexPath?
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
            as! SendProfileViewCell
        if indexPath.section == 0 {
            cell.label.text = gps_service.currentCity!.name
            cell.subtitle.text = gps_service.currentCity!.country
            cell.lockState(true)
        } else {
            cell.label.text = likelihoods[indexPath.row].place.name
            if let address = likelihoods[indexPath.row].place.formattedAddress {
                cell.subtitle.text = getShortFormattedAddress(address)
            } else {
                cell.subtitle.text = ""
            }
            cell.toggleSelection(false)
        }
        
        
        return cell
    }
    
    var selectedIndex:IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = likelihoods[indexPath.row].place
        
        let currentCell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
        if indexPath.section == 1 {
            if currentCell.isActive {
                currentCell.toggleSelection(false)
                selectedIndex =  nil
                upload.place = nil
                sendLabel.text = "My location"
                if let location = gps_service.getLastLocation() {
                    mapView?.animate(toLocation: location.coordinate)
                }
            } else {
                if let oldPath = selectedIndex {
                    let oldCell = tableView.cellForRow(at: oldPath) as! SendProfileViewCell
                    oldCell.toggleSelection(false)
                }
                currentCell.toggleSelection(true)
                selectedIndex =  indexPath
                upload.place = place
                sendLabel.text = place.name
                mapView?.animate(toLocation: place.coordinate)
            }
        }
        
    }
    
}

extension SendViewController: GPSServiceProtocol {
    func authorizationDidChange() {
        
    }

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
