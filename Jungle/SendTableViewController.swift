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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "SendProfileViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "profileCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()

        tableView.reloadData()

        sendTap = UITapGestureRecognizer(target: self, action: #selector(send))
        
        toggleSend()
        getCurrentPlaces()
                
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.isTranslucent = false
        
    }
    @IBAction func handleBack(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    
    func getCurrentPlaces() {
        
        placesClient = GMSPlacesClient.shared()
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }

            if let placeLikelihoodList = placeLikelihoodList {
                var temp = [GMSPlaceLikelihood]()
                for likelihood in placeLikelihoodList.likelihoods {
//                    if likelihood.likelihood >= 0.25 {
//                        temp.append(likelihood)
//                    }
                    
                    
                    temp.append(likelihood)
                }
                self.likelihoods = temp
                self.tableView.reloadData()
                
            }
        })
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
