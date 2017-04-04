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

class NotificationsViewController: RoundedViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    
    let cellIdentifier = "notificationCell"
    let followCellIdentifier = "followCell"
    var notifications = [Notification]()
    
    var tableView:UITableView!
    
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
        
        tableView = UITableView(frame: CGRect(x: 0,y: 44,width: view.frame.width ,height: view.frame.height - 44))
        
        let nib = UINib(nibName: "NotificationTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        
        let nib2 = UINib(nibName: "NotificationFollowCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: followCellIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        view.backgroundColor = UIColor.clear
        view.addSubview(tableView)
        
        //conversations = getNonEmptyConversations()
        //conversations.sort(by: { $0 > $1 })
        notifications = mainStore.state.notifications
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        mainStore.dispatch(MarkAllNotifcationsAsSeen())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        notifications = mainStore.state.notifications
        notifications.sort(by: { $0 > $1 })
        tableView.reloadData()
        
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
        if notification.getType() == .comment {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! NotificationTableViewCell
            cell.setup(withNotification: notifications[indexPath.row])
            let labelX = cell.messageLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: followCellIdentifier, for: indexPath) as! NotificationFollowCell
            cell.setup(withNotification: notifications[indexPath.row])
            cell.unfollowHandler = unfollowHandler
            let labelX = cell.messageLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let notification = notifications[indexPath.row]
        if notification.getType() == .comment {
            let cell = tableView.cellForRow(at: indexPath) as! NotificationTableViewCell
            
            if let item = cell.post {
                let i = IndexPath(item: indexPath.row, section: 0)
                globalMainRef?.presentNotificationPost(post: item, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            }
        }
        
    }
    
    func unfollowHandler(user:User) {
        let actionSheet = UIAlertController(title: nil, message: "Unfollow \(user.getUsername())?", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Unfollow", style: .destructive)
        { action -> Void in
            
            UserService.unfollowUser(uid: user.getUserId())
        }
        actionSheet.addAction(saveActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
    }

}
