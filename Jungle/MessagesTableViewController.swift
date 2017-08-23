//
//  MessagesTableViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

class MessagesViewController: RoundedViewController, StoreSubscriber, UITableViewDelegate, UITableViewDataSource, MessageServiceProtocol {

    let identifier = "MessagesViewController"
    let cellIdentifier = "conversationCell"
    
    weak var message_service:MessageService?
    
    fileprivate var conversations = [Conversation]()
    
    private(set) var tableView:UITableView!
    
    var searchBar:UISearchBar!
    var refreshIndicator:UIActivityIndicatorView!
    var cancelButton:UIButton!
    var searchMode = false
    
    var userSearchResults = [String]()
    
    var emptyView:EmptyMessagesView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width - 96, height: 44))
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightMedium)
        label.text = "Messages"
        label.textAlignment = .center
        label.center = CGPoint(x: view.frame.width/2, y: 22)
        //view.addSubview(label)
        
        
        
        
        tableView = UITableView(frame: CGRect(x: 0,y: 44,width: view.frame.width ,height: view.frame.height - 44))
        
        let nib2 = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "userCell")
        
        let nib = UINib(nibName: "ConversationViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        emptyView = UINib(nibName: "EmptyMessagesView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EmptyMessagesView
        
        let msg = "Send a direct message to someone to start a conversation!"
        let size = UILabel.size(withText: msg, forWidth: tableView.frame.width - (24 + 16), withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium))
        emptyView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: size.height + 16 + 16 + 12 + 12 + 8 + emptyView.titleLabel.frame.height)
        emptyView.detailLabel.text = msg
        
        view.backgroundColor = UIColor.clear
        view.addSubview(tableView)
        
        tableView.reloadData()
        
        cancelButton = UIButton(frame: CGRect(x: 0, y: 0.0, width: 44.0, height: 44.0))
        cancelButton.setImage(UIImage(named: "navback"), for: .normal)
        cancelButton.tintColor = UIColor.gray
        cancelButton.addTarget(self, action: #selector(cancelSearch), for: .touchUpInside)
        cancelButton.isHidden = true
        view.addSubview(cancelButton)
        
        
        searchBar = UISearchBar(frame:CGRect(x: 44, y: 0, width: view.frame.width - 88, height: 44))
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        refreshIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        refreshIndicator.frame = CGRect(x: view.frame.width - 44.0, y: 0.0, width: 44.0, height: 44.0)
        refreshIndicator.hidesWhenStopped = true
        
        view.addSubview(refreshIndicator)
        
        //refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        message_service?.subscribe(identifier, subscriber: self)
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        message_service?.unsubscribe(identifier)
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    
    func newState(state: AppState) {
        self.tableView.tableHeaderView = conversations.count == 0 && !searchMode ? emptyView : UIView()
        self.tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func conversationsUpdated(_ conversations: [Conversation]) {
        print("DEM CONVOS UPDATED")
        self.conversations = conversations
        self.tableView.tableHeaderView = conversations.count == 0 && !searchMode ? emptyView : UIView()
        tableView.reloadData()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if searchMode {
            return 60
        }
        return 68
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchMode {
            return userSearchResults.count
        }
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if searchMode {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserViewCell
            cell.setupUser(uid: userSearchResults[indexPath.row])
            cell.delegate = self
            let labelX = cell.usernameLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ConversationViewCell
        
        cell.conversation = conversations[indexPath.item]
        let labelX = cell.usernameLabel.frame.origin.x
        cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if searchMode {
            let controller = UserProfileViewController()
            controller.uid = userSearchResults[indexPath.row]
            globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
        } else {
            let cell = tableView.cellForRow(at: indexPath) as! ConversationViewCell
            if let user = cell.user, let image = cell.userImageView.image {
                let controller = ChatViewController()
                controller.partnerImage = image
                controller.partner = user
                globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func keyboardWillAppear() {
        globalMainInterfaceProtocol?.setScrollState(false)
    }
    
    func keyboardWillDisappear() {
        globalMainInterfaceProtocol?.setScrollState(true)
    }
    
}

extension MessagesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let text = searchText.lowercased()
        searchBar.text = text
        refreshIndicator.startAnimating()
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("api/requests/user_search/\(uid)")
        ref.setValue(searchBar.text)
        
    }
    
    func observeSearchResponse() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("api/responses/user_search/\(uid)")
        ref.observe(.value, with: { snapshot in
            
            var uids = [String]()
            if let dict = snapshot.value as? [String:String] {
                for (userId,_) in dict {
                    if mainStore.state.socialState.followers.contains(userId) || mainStore.state.socialState.following.contains(userId) {
                        uids.insert(userId, at: 0)
                    } else {
                        uids.append(userId)
                    }
                }
            }
            self.refreshIndicator.stopAnimating()
            self.userSearchResults = uids
            if self.searchMode {
                self.tableView.reloadData()
            }
        })
    }
    
    func stopObservingSearchResponse() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("api/responses/user_search/\(uid)")
        ref.removeAllObservers()
        ref.removeAllObservers()
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.tableView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchMode = true
        observeSearchResponse()
        cancelButton.isHidden = false
        self.tableView.reloadData()
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func cancelSearch() {
        self.searchBar.resignFirstResponder()
        searchMode = false
        cancelButton.isHidden = true
        self.refreshIndicator.stopAnimating()
        self.tableView.reloadData()
        stopObservingSearchResponse()
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("LIKE WHOA")
        if let touch = touches.first {
            if #available(iOS 9.0, *) {
                if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
                    if touch.force >= touch.maximumPossibleForce {
                        print("385+ grams")
                    } else {
                        let force = touch.force/touch.maximumPossibleForce
                        let grams = force * 385
                        let roundGrams = Int(grams)
                        print("\(roundGrams) grams")
                    }
                }
            }
        }
    }
}

extension MessagesViewController: UserCellProtocol {
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

