//
//  SettingsViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-23.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase

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

    @IBOutlet weak var emailCell: UITableViewCell!
    @IBOutlet weak var pushNotificationsSwitch: UISwitch!
    
    @IBOutlet weak var flaggedContentSwitch: UISwitch!
    
    @IBOutlet weak var blockedUsersCell: UITableViewCell!
    
    @IBOutlet weak var privacyPolicyCell: UITableViewCell!
    
    @IBOutlet weak var termsCell: UITableViewCell!
    
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    
    deinit {
        print("Deinit >> SettingsViewController")
    }
    
    var notificationsRef:DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        self.navigationController?.navigationBar.tintColor = UIColor.black
        
        let uid = mainStore.state.userState.uid
        notificationsRef = UserService.ref.child("users/settings/\(uid)/push_notifications")
        notificationsRef?.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                if let val = snapshot.value as? Bool {
                    self.pushNotificationsSwitch.setOn(val, animated: false)
                }
            } else {
                self.pushNotificationsSwitch.setOn(true, animated: false)
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let email = UserService.email {
            emailCell.detailTextLabel?.text = email
        } else {
            emailCell.detailTextLabel?.text = "Missing!"
        }
        
        emailCell.detailTextLabel?.textColor = UserService.isEmailVerified ? UIColor.lightGray : errorColor
        emailCell.textLabel?.textColor = UserService.isEmailVerified ? UIColor.black : errorColor
        
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
            showLogoutView()
            break
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func pushNotificationsSwitched(_ sender: UISwitch) {
        if sender.isOn {
            notificationsRef?.setValue(true)
        } else {
            notificationsRef?.setValue(false)
        }
    }
    
    @IBAction func flaggedContentSwitched(_ sender: UISwitch) {
        
    }
    
    func showLogoutView() {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Log Out", style: .destructive)
        { action -> Void in
            UserService.logout()
        }
        actionSheet.addAction(saveActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
    }

}
