//
//  NotificationsViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import UIKit

class NotificationsViewController: RoundedViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber, NotificationServiceProtocol {
    
    private let identifier = "NotificationsViewController"
    
    private let cellIdentifier = "notificationCell"
    private let followCellIdentifier = "followCell"
    private let badgeCellIdentifier = "badgeCell"
    private var notifications = [Notification]()
    
    var refreshIndicator:UIActivityIndicatorView!
    
    weak var notification_service:NotificationService?
    
    var tableView:UITableView!
    var emptyView:EmptyMessagesView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width - 96, height: 44))
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightMedium)
        label.text = "Notifications"
        label.textAlignment = .center
        label.center = CGPoint(x: view.frame.width/2, y: 22)
        view.addSubview(label)
        
        let bar = UIView(frame: CGRect(x: 0, y: 43.5, width: view.frame.width, height:0.5))
        bar.backgroundColor = UIColor(white: 0.80, alpha: 1.0)
        view.addSubview(bar)
        
        refreshIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        refreshIndicator.frame = CGRect(x: view.frame.width - 44.0, y: 0, width: 44.0, height: 44.0)
        refreshIndicator.hidesWhenStopped = true
        
        view.addSubview(refreshIndicator)
        
        tableView = UITableView(frame: CGRect(x: 0,y: 44,width: view.frame.width ,height: view.frame.height - 44))
        
        let nib = UINib(nibName: "NotificationTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        
        let nib2 = UINib(nibName: "NotificationFollowCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: followCellIdentifier)
        
        let nib3 = UINib(nibName: "NotificationBadgeCell", bundle: nil)
        tableView.register(nib3, forCellReuseIdentifier: badgeCellIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 68))
        tableView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        emptyView = UINib(nibName: "EmptyMessagesView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EmptyMessagesView
        
        let msg = "Notifications that you recieve from new followers, comments, & likes will be shown here."
        let size = UILabel.size(withText: msg, forWidth: tableView.frame.width - (24 + 16), withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium))
        emptyView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: size.height + 16 + 16 + 12 + 12 + 8 + emptyView.titleLabel.frame.height)
        emptyView.titleLabel.text = "No notifications."
        emptyView.detailLabel.text = msg
        
        view.backgroundColor = UIColor.clear
        view.addSubview(tableView)
        //getAllNotifications()
        tableView.tableHeaderView = notifications.count == 0 ? emptyView : UIView()
        tableView.reloadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        mainStore.subscribe(self)
        notification_service?.subscribe(identifier, subscriber: self)
        notification_service?.markAllNotificationsAsSeen()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        notification_service?.unsubscribe(identifier)
    }
    
    func notificationsUpdated(_ notificationsDict: [String : Bool]) {
        guard let service = notification_service else { return }
        if notificationsDict.count == 0 {
            self.tableView.reloadData()
            self.refreshIndicator.stopAnimating()
            return
        }
        
        var tempNotifications = [Notification]()
        var count = 0
        refreshIndicator.startAnimating()
        for (key, _) in notificationsDict {
            service.getNotification(key, completion: { notification, seen in
                if notification != nil {
                    tempNotifications.append(notification!)
                }
                count += 1
                if count >= notificationsDict.count {
                    count = -1
                    self.notifications = tempNotifications.sorted(by: { $0 > $1 })
                    self.tableView.tableHeaderView = self.notifications.count == 0 ? self.emptyView : UIView()
                    self.tableView.reloadData()
                    self.refreshIndicator.stopAnimating()
                }
            })
        }

    }
    
    
    func newState(state: AppState) {
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notification = notifications[indexPath.row]
        let type = notification.type
        if type == .comment || type == .comment_also || type == .comment_to_sub || type == .like || type == .mention {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! NotificationTableViewCell
            cell.setup(withNotification: notifications[indexPath.row])
            let labelX = cell.messageLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            cell.userTappedHandler = showUser
            return cell
        } else if type == .follow {
            let cell = tableView.dequeueReusableCell(withIdentifier: followCellIdentifier, for: indexPath) as! NotificationFollowCell
            cell.setup(withNotification: notifications[indexPath.row])
            cell.unfollowHandler = unfollowHandler
            let labelX = cell.messageLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: badgeCellIdentifier, for: indexPath) as! NotificationBadgeCell
            cell.iconLabel.text = ""
            let notification = notifications[indexPath.row]
            cell.setLabel(date: notification.date)
            if let badgeID = notifications[indexPath.row].text {
                if let badge = badges[badgeID] {
                    cell.iconLabel.text = badge.icon
                }
            }
            
            let labelX = cell.label.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let notification = notifications[indexPath.row]
        let type = notification.type
        if type == .comment || type == .comment_also || type == .comment_to_sub || type == .like || type == .mention {
            let cell = tableView.cellForRow(at: indexPath) as! NotificationTableViewCell
            
            if let item = cell.post {
                let i = IndexPath(item: 0, section: 0)
                globalMainInterfaceProtocol?.presentNotificationPost(post: item, destinationIndexPath: i, initialIndexPath: indexPath)
            }
        } else if type == .follow {
            showUser(notification.sender)
        } else if type == .badge {
            let controller = UIStoryboard(name: "EditProfileViewController", bundle: nil)
                .instantiateViewController(withIdentifier: "EditProfileNavigationController") as! UINavigationController
            globalMainInterfaceProtocol?.presentPopover(withController: controller, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

       let notification = notifications[indexPath.row]
        
        var action:UITableViewRowAction!

        action = UITableViewRowAction(style: .normal, title: "Remove") { (rowAction, indexPath) in
            //self.showDeleteCommentAlert(self.comments[indexPath.row])
            UserService.ref.child("users/notifications/\(userState.uid)/\(notification.key)").removeValue() { error, ref in
                if error != nil {
                    Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Unable to remove notification.")
                } else {
                    Alerts.showStatusSuccessAlert(inWrapper: nil, withMessage: "Notification removed!")
                }
                
                
            }
        }
        action.backgroundColor = errorColor.withAlphaComponent(0.75)

        return [action]
    }
    
    func showUser(_ uid:String) {
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = UserProfileViewController()
        controller.uid = uid
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func unfollowHandler(user:User) {
        let actionSheet = UIAlertController(title: nil, message: "Unfollow \(user.username)?", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Unfollow", style: .destructive)
        { action -> Void in
            
            UserService.unfollowUser(uid: user.uid)
        }
        actionSheet.addAction(saveActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
    }

}
