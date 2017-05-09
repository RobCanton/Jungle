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
        self.addNavigationBarBackdrop()
        
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
            UserService.logout()
            break
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func pushNotificationsSwitched(_ sender: UISwitch) {
        
    }
    
    @IBAction func flaggedContentSwitched(_ sender: UISwitch) {
        
    }

}
