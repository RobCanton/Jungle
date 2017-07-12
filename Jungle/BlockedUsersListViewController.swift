//
//  BlockedUsersListViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-12.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

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

class BlockedUsersListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    

    var tableView:UITableView!

    var navHeight:CGFloat!
    
    let cellIdentifier = "userCell"

    var blockedUsers = [String]()
    var blockedAnonymousUsers = [(String,Double)]()
    
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
        blockedUsers = mainStore.state.socialState.blocked.sorted()
        blockedAnonymousUsers = mainStore.state.socialState.blockedAnonymous
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        self.addNavigationBarBackdrop()
        title = "Blocked Users"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        tableView = UITableView(frame:  CGRect(x: 0,y: navHeight, width: view.frame.width,height: view.frame.height - navHeight))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.white
        
        view.addSubview(tableView)
        
        let nib = UINib(nibName: "BlockedUserTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        tableView.reloadData()
        
        view.backgroundColor = UIColor.white
        
        blockedUsers = mainStore.state.socialState.blocked.sorted()
        blockedAnonymousUsers = mainStore.state.socialState.blockedAnonymous
        
        print("BlockedUsers")
        print(blockedUsers)
        print("BlockedAnonymousUsers")
        print(blockedAnonymousUsers)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedAnonymousUsers.count + blockedUsers.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BlockedUserTableViewCell
        cell.delegate = self
        if indexPath.row < blockedAnonymousUsers.count {
            let pair = blockedAnonymousUsers[indexPath.row ]
            cell.isAnon = true
            cell.id = pair.0
            cell.setAnonymousUser(pair.0, pair.1)
        } else {
            let row = indexPath.row - blockedAnonymousUsers.count
            let user = blockedUsers[row]
            cell.isAnon = false
            cell.id = user
            cell.setUser(user)
        }
        let labelX = cell.usernameLabel.frame.origin.x
        cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let controller = UserProfileViewController()
//        controller.uid = userIds[indexPath.row]
//        self.navigationController?.pushViewController(controller, animated: true)
//        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    func addDoneButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        self.navigationItem.rightBarButtonItem  = doneButton
    }
    
    
    
    func doneTapped() {
        self.performSegue(withIdentifier: "showLit", sender: self)
    }
}

extension BlockedUsersListViewController: BlockedUserCellProtocol {
    func blockUser(_ id:String, _ isAnon:Bool) {
        
        let alert = UIAlertController(title: "Unblock user?", message: "This user will be able to see your posts and send you messages again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Unblock", style: .destructive, handler: { _ in
                if isAnon {
                    UserService.unblockAnonUser(aid: id, completion: { success in })
                } else {
                    UserService.unblockUser(uid: id, completion: { success in })
                }
            }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}


