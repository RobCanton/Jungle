//
//  UsersListViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift
import UIKit

enum UsersListType {
    case Followers, Following, None
}

protocol UserCellProtocol:class {
    func unfollowHandler(_ user:User)
}

class UsersListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    
    var location:Location?
    var uid:String?
    var postKey:String?
    var tableView:UITableView!
    var showFollowButton = true
    var navHeight:CGFloat!
    
    let cellIdentifier = "userCell"
    var user:User?
    var type = UsersListType.None
    
    var userIds = [String]()
    {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var tempIds = [String]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        
        tableView.reloadData()
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
    
        
        if tempIds.count > 0 {
            userIds = tempIds
        } else if type == .Followers && uid != nil {
            title = "Followers"
            let ref = Database.database().reference().child("social/followers/\(uid!)")
            ref.observeSingleEvent(of: .value, with: { snapshot in
                var tempIds = [String]()
                for child in snapshot.children {
                    let childSnap = child as! DataSnapshot
                    tempIds.append(childSnap.key)
                }
                self.userIds = tempIds
                self.tableView.reloadData()
                
            }, withCancel: { error in
                print("Unable to retrieve followers")
            })
        } else if type == .Following && uid != nil {
            title = "Following"
            let ref = Database.database().reference().child("social/following/\(uid!)")
            ref.observeSingleEvent(of: .value, with: { snapshot in
                var tempIds = [String]()
                for child in snapshot.children {
                    let childSnap = child as! DataSnapshot
                    tempIds.append(childSnap.key)
                }
                self.userIds = tempIds
                self.tableView.reloadData()
                
            }, withCancel: { error in
                print("Unable to retrieve followers")
            })
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userIds.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! UserViewCell
        cell.setupUser(uid: userIds[indexPath.row])
        cell.delegate = self
        let labelX = cell.usernameLabel.frame.origin.x
        cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = UserProfileViewController()
        controller.uid = userIds[indexPath.row]
        self.navigationController?.pushViewController(controller, animated: true)
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    func addDoneButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        self.navigationItem.rightBarButtonItem  = doneButton
    }
    
    
    
    func doneTapped() {
        self.performSegue(withIdentifier: "showLit", sender: self)
    }
}

extension UsersListViewController: UserCellProtocol {
    func unfollowHandler(_ user:User) {
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
