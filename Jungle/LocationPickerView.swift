//
//  LocationPickerView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-27.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import GooglePlaces

protocol LocationPickerDelegate:class {
    func locationPicked(_ place:GMSPlaceLikelihood)
}

class LocationPickerView: UIView, UITableViewDelegate, UITableViewDataSource {
   
    var places = [GMSPlaceLikelihood]()

    @IBOutlet weak var tableView: UITableView!
    
    var locationPicked: ((_ place:GMSPlaceLikelihood?)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.backgroundColor = UIColor.clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.25)
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
    }
    
    func setup() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        cell.contentView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightMedium)
        cell.textLabel?.textColor = UIColor.white
        if indexPath.row == 0 {
            cell.textLabel?.text = "None"
            
        } else {
            let place = places[indexPath.row - 1]
            cell.textLabel?.text = place.place.name
        }
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            locationPicked?(nil)
        } else {
            let place = places[indexPath.row - 1]
            locationPicked?(place)
        }
    }
    
    
    
}
