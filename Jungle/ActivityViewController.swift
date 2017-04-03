//
//  ActivityViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Firebase
import View2ViewTransition

class ActivityViewController: RoundedViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var myStory:Story?

    var userStories = [Story]()
    var postKeys = [String]()
    
    var storiesDictionary = [String:[String]]()
    
    var returningCell:UserStoryTableViewCell?
    
    var myStoryRef:FIRDatabaseReference?
    var responseRef:FIRDatabaseReference?
    
    var statusBarShouldHide = false
    
    var tableView:UITableView!
    
    override var prefersStatusBarHidden: Bool
        {
        get{
            return statusBarShouldHide
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenToMyStory()
        
        NotificationCenter.default.addObserver(self, selector:#selector(handleEnterForeground), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        myStoryRef?.removeAllObservers()
        responseRef?.removeAllObservers()
        
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleEnterForeground() {
        myStory?.determineState()
        for story in self.userStories {
            story.determineState()
        }
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        if returningCell != nil {
            returningCell!.activate(true)
            returningCell = nil
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    @IBAction func showUserSearch(sender: AnyObject) {
        
        let controller = UIStoryboard(name: "UserSearchViewController", bundle: nil)
            .instantiateViewController(withIdentifier: "UserSearchViewController")
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    func listenToMyStory() {
        guard let user = FIRAuth.auth()?.currentUser else { return }
        let uid = user.uid
        myStoryRef = UserService.ref.child("users/activity/\(uid)")
        myStoryRef?.removeAllObservers()
        myStoryRef?.observe(.value, with: { snapshot in
            
            var postKeys = [(String,Double)]()
            if let _postsKeys = snapshot.value! as? [String:Double] {
                postKeys = _postsKeys.valueKeySorted
                for (key, value) in postKeys {
                    print(key, value)
                }
            }

            if postKeys.count > 0 {
                let myStory = Story(postKeys: postKeys)
                self.myStory = myStory
            } else{
                self.myStory = nil
            }
            self.tableView.reloadData()
        })
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.title = "Activity"
        
        tableView = UITableView(frame: view.bounds)
        
        let nib = UINib(nibName: "UserStoryTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "UserStoryCell")
        tableView.backgroundColor = UIColor.black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = true
        tableView.isPagingEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: tableView!.frame.width,height: 160))
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        tableView.reloadData()
        
    }
    
    func showMessages() {
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ListHeaderView
        if section == 0 {
            headerView.isHidden = true
        }
        if section == 1 && userStories.count > 0 {
            headerView.isHidden = false
        }
        
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && userStories.count > 0 {
            return 28
        }
        return 14
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        default:
            return 76
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return userStories.count
        default:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserStoryCell", for: indexPath) as! UserStoryTableViewCell
            if myStory != nil {
                cell.setUserStory(myStory!, uid: FIRAuth.auth()!.currentUser!.uid)
            } else {
                cell.setToEmptyMyStory()
            }
            return cell
        
    }
    

    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
}

