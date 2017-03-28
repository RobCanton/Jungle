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

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var sendLabel: UILabel!
    
    var placesClient: GMSPlacesClient!
    
    var likelihoods = [GMSPlaceLikelihood]()
    var upload:Upload!
    
    var sendTap:UITapGestureRecognizer!
    var containerRef:MainViewController!
    
    var headerView:UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Send To..."
        let nib = UINib(nibName: "SendProfileViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "profileCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        headerView  = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 275))
        
        let location = GPSService.sharedInstance.lastSignificantLocation
        let camera = GMSCameraPosition.camera(withTarget: location!.coordinate, zoom: 19.0)
        let mapView = GMSMapView.map(withFrame: headerView.bounds, camera: camera)
        headerView.addSubview(mapView)
        mapView.backgroundColor = UIColor.black
        mapView.isMyLocationEnabled = true
        mapView.settings.scrollGestures = false
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = false
        mapView.isBuildingsEnabled = true
        mapView.isIndoorEnabled = true
        
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        tableView.tableHeaderView = headerView
        
        tableView.tableFooterView = UIView()

        tableView.reloadData()

        sendTap = UITapGestureRecognizer(target: self, action: #selector(send))
        
        toggleSend()
        self.likelihoods = GPSService.sharedInstance.likelihoods
        
        for likelihood in self.likelihoods {
            let marker = GMSMarker(position: likelihood.place.coordinate)
            marker.title = likelihood.place.name
            marker.map = mapView
        }
        
        self.tableView.reloadData()
                
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.isTranslucent = false
        
    }
    @IBAction func handleBack(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }

    func sent() {
        containerRef.cameraView.cameraState = .Initiating
        containerRef.recordBtn.isHidden = false
        self.dismiss(animated: true, completion: nil)
    }
    
    func send() {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.startAnimating()
        activityIndicator.center = sendView.center
        view.addSubview(activityIndicator)
        
        sendLabel.isHidden = true
        
        
        if let videoURL = upload.videoURL {
            //            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            //            let outputUrl = documentsURL.appendingPathComponent("output.mp4")
            //
            //            do {
            //                try FileManager.default.removeItem(at: outputUrl)
            //            }
            //            catch let error as NSError {
            //                if error.code != 4 && error.code != 2 {
            //                    return print("Error \(error)")
            //                }
            //            }
            //            upload.videoURL = outputUrl
            //
            //            UploadService.compressVideo(inputURL: videoURL, outputURL: outputUrl, handler: { session in
            //                DispatchQueue.main.async {
            //                    UploadService.uploadVideo(upload: self.upload, completion: { success in
            //                        self.sent()
            //                    })
            //                }
            //            })
            
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
        cell.subtitle.text = "\(likelihoods[indexPath.row].likelihood)"
        return cell
    }
    
    var selectedIndex:IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let place = likelihoods[indexPath.row].place
        upload.place = place
        if let oldPath = selectedIndex {
            let oldCell = tableView.cellForRow(at: oldPath) as! SendProfileViewCell
            oldCell.toggleSelection(false)
        }
        
        let currentCell = tableView.cellForRow(at: indexPath) as! SendProfileViewCell
        currentCell.toggleSelection(true)
        selectedIndex =  indexPath
        
        toggleSend()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func toggleSend() {
        if upload.place != nil {
            sendView.backgroundColor = accentColor
            sendLabel.textColor = UIColor.white
            sendView.isUserInteractionEnabled = true
            sendView.addGestureRecognizer(sendTap)
        } else {
            sendView.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
            sendLabel.textColor = UIColor.lightGray
            sendView.isUserInteractionEnabled = false
            sendView.removeGestureRecognizer(sendTap)
        }
    }
}
