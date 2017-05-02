//
//  TypesEditorViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-01.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

//
//  UsersListViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift
import UIKit

let all_place_types = [
    ("airport","Airport"), ("amusement_park", "Amusement Park"), ("aquarium", "Aquarium"), ("art_gallery", "Art Gallery"),
    ("bakery","Bakery"), ("bank","Bank"), ("bar", "Bar"), ("bicycle_store", "Bicycle Store"), ("book_store", "Book Store"), ("bowling_alley", "Bowling Alley"),
    ("cafe","Cafe"), ("campground","Campground"), ("car_dealer", "Car Dealer"), ("Car Rental", "Bicycle Store"), ("book_store", "Book Store"), ("bowling_alley", "Bowling Alley"),
    

    
    /*"cafe", "campground", "car_dealer", "car_rental", "car_repair", "car_wash",
    "casino", "church", "city_hall", "clothing_store", "convenience_store",
    "dentist","department_store", "doctor", "electrician_store", "embassy",
    "fire_station", "furniture_store", "gas_station", "gym", "hair_care",
    "hardware_store", "home_goods_store", "hospital", "jewelry_store",
    "laundry", "lawyer", "library", "liquor_store", "local_government_office",
    "locksmith", "lodging", "mosque", "movie_theater", "museum", "night_club",
    "park", "parking", "pet_store", "pharmacy", "physiotherapist", "police",
    "post_office", "restuarant", "school", "shopping_mall", "spa", "stadium",
    "store", "university", "zoo"*/
]

let general_types = [
    ("stores", "Stores"), ("parks", "Parks"), ("bars&nightclubs", "Bars & Night Clubs"), ("automotive", "Automotive"), ("museums", "Museums and Galleries"), ("bowling_alley", "Bowling Alley"), ("library", "Libraries")
]

class TypesEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView:UITableView!
    var navHeight:CGFloat!
    
    let cellIdentifier = "userCell"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        self.addNavigationBarBackdrop()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        tableView = UITableView(frame:  CGRect(x: 0,y: navHeight, width: view.frame.width,height: view.frame.height - navHeight))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.white
        
        view.addSubview(tableView)
        
        let nib = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        tableView.reloadData()
        
        view.backgroundColor = UIColor.white
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! UserViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    

    
}
