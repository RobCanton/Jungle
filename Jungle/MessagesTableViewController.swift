//
//  MessagesTableViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import ReSwift
import UIKit

class MessagesViewController: RoundedViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {

    let cellIdentifier = "conversationCell"
    
    var conversations = [Conversation]()
    
    var tableView:UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        
        var searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.frame.width - 108, height: 44 - 16))
        searchBar.center = CGPoint(x: view.frame.width/2, y: 22)
        searchBar.barStyle = .default
        //searchBar.barTintColor = UIColor.red
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        view.addSubview(searchBar)
        
        
        tableView = UITableView(frame: CGRect(x: 0,y: 44,width: view.frame.width ,height: view.frame.height - 44))
        
        let nib = UINib(nibName: "ConversationViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        view.backgroundColor = UIColor.clear
        view.addSubview(tableView)
        
        conversations = getNonEmptyConversations()
        conversations.sort(by: { $0 > $1 })
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        
        conversations = getNonEmptyConversations()
        conversations.sort(by: { $0 > $1 })
        tableView.reloadData()
        
    }
    
    func checkForExistingConversation(partner_uid:String) -> Conversation? {
        for conversation in conversations {
            if conversation.getPartnerId() == partner_uid {
                return conversation
            }
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ConversationViewCell
        
        cell.conversation = conversations[indexPath.item]
        let labelX = cell.usernameLabel.frame.origin.x
        cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        prepareConverstaionForPresentation(conversation: conversations[indexPath.row])
    }
    
    func prepareConverstaionForPresentation(conversation:Conversation) {
        if let user = conversation.getPartner() {
            presentConversation(conversation: conversation, user: user)
        } else {
            UserService.getUser(conversation.getPartnerId(), completion: { user in
                if user != nil {
                    self.presentConversation(conversation: conversation, user: user!)
                }
            })
        }
    }
    
    func presentConversation(conversation:Conversation, user:User) {
        loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromCache in
            let controller = ChatViewController()
            controller.conversation = conversation
            controller.partnerImage = image
            globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
        })
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            let cell = tableView.cellForRow(at: indexPath) as! ConversationViewCell
//            let name = cell.usernameLabel.text!
//            
//            let actionSheet = UIAlertController(title: "Delete conversation with \(name)?", message: "Further messages from \(name) will be muted until you reply.", preferredStyle: .alert)
//            
//            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
//            }
//            
//            actionSheet.addAction(cancelActionButton)
//            
//            let saveActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive)
//            { action -> Void in
//                UserService.muteConversation(conversation: self.conversations[indexPath.row])
//            }
//            actionSheet.addAction(saveActionButton)
//            
//            self.present(actionSheet, animated: true, completion: nil)
//        }
//    }
    
}
