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
import ReSwift

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

class SettingsViewController: UITableViewController, StoreSubscriber {

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
        mainStore.subscribe(self)
        if let email = UserService.email {
            emailCell.detailTextLabel?.text = email
        } else {
            emailCell.detailTextLabel?.text = "Missing!"
        }
        
        emailCell.detailTextLabel?.textColor = UserService.isEmailVerified ? UIColor.lightGray : errorColor
        emailCell.textLabel?.textColor = UserService.isEmailVerified ? UIColor.black : errorColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        flaggedContentSwitch.isOn = state.settingsState.allowFlaggedContent
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = self.tableView.cellForRow(at: indexPath) else { return }
        
        switch cell {
        case blockedUsersCell:
            let controller = UsersListViewController()
            controller.uid = mainStore.state.userState.uid
            controller.type = .Blocked
            globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
            break
        case privacyPolicyCell:
            let web = WebViewController()
            web.shouldAddBackdrop = true
            web.title = "Privacy Policy"
            web.urlString = "https://jungleapp.info/privacypolicy.html"
            globalMainInterfaceProtocol?.navigationPush(withController: web, animated: true)
            break
        case termsCell:
            let web = WebViewController()
            web.shouldAddBackdrop = true
            web.title = "Terms of Use"
            web.urlString = "https://jungleapp.info/terms.html"
            globalMainInterfaceProtocol?.navigationPush(withController: web, animated: true)
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
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("users/settings/\(uid)/allows_flagged_content")
        if sender.isOn {
            ref.setValue(true)
        } else {
            ref.removeValue()
        }
        
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
