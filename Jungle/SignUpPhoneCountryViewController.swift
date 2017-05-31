//
//  SignUpPhoneCountryViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-29.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

protocol CountrySelectionProtocol: class {
    func didSelectCountry(_ country: Country)
}

struct Country {
    var code: String
    var name: String
    var phoneCode: String
    
    init(code: String, name: String, phoneCode: String) {
        self.code = code
        self.name = name
        self.phoneCode = phoneCode
    }
}

class SignUpPhoneCountryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var countries:[Country]!
    
    weak var delegate:CountrySelectionProtocol?
    
    deinit {
        print("Deinit >> SignUpPhoneCountryViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "countryCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        countries = countryNamesByCode()
    }
    
    @IBAction func handleDismiss(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countryCell", for: indexPath)
        let country = countries[indexPath.row]
        cell.textLabel?.text = "\(country.name) (\(country.phoneCode))"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = countries[indexPath.row]
        delegate?.didSelectCountry(country)
        tableView.deselectRow(at: indexPath, animated: true)
        self.dismiss(animated: false, completion: nil)
    }
    
    func countryNamesByCode() -> [Country] {
        var countries = [Country]()
        
        if let path = Bundle.main.path(forResource: "countryCodes", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                if let jsonObj = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSArray {
                    for jsonObject in jsonObj {
                        
                        guard let countryObj = jsonObject as? NSDictionary else {
                            return countries
                        }
                        
                        guard let code = countryObj["code"] as? String, let phoneCode = countryObj["dial_code"] as? String, let name = countryObj["name"] as? String else {
                            return countries
                        }
                        
                        print("COUNTRY: \(name)")
                        
                        let country = Country(code: code, name: name, phoneCode: phoneCode)
                        countries.append(country)
                    }
                }
                
            } catch let error {
                return countries
            }
        } else {
            print("Invalid filename/path.")
        }
        
        
        
        return countries
    }
    
}
