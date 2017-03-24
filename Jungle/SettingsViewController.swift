//
//  SettingsViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-23.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class SettingsContainerViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        if let navbar = navigationController?.navigationBar {
            let blurView = UIView(frame: CGRect(x: 0, y: 0, width: navbar.frame.width, height: navbar.frame.height + 20.0))
            blurView.backgroundColor = UIColor.white
            self.view.insertSubview(blurView, belowSubview: navbar)
        }
        
        self.navigationController?.navigationBar.tintColor = UIColor.black
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barStyle = .default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var pushNotificationsSwitch: UISwitch!
    
    @IBOutlet weak var flaggedContentSwitch: UISwitch!
    
    @IBOutlet weak var blockedUsersCell: UITableViewCell!
    
    @IBOutlet weak var privacyPolicyCell: UITableViewCell!
    
    @IBOutlet weak var termsCell: UITableViewCell!
    
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        self.navigationController?.navigationBar.tintColor = UIColor.black
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = self.tableView.cellForRow(at: indexPath) else { return }
        
        switch cell {
        case blockedUsersCell:
            break
        case privacyPolicyCell:
            break
        case termsCell:
            break
        case logoutCell:
            AuthService.sharedInstance.logout()
            break
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    

    @IBAction func radiusSliderChanged(_ sender: UISlider) {
        
    }
    
    @IBAction func pushNotificationsSwitched(_ sender: UISwitch) {
        
    }
    
    @IBAction func flaggedContentSwitched(_ sender: UISwitch) {
        
    }

}