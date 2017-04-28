//
//  CommentsViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-16.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase

enum PostInfoMode {
    case Viewers, Comments
}

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    var mode:PostInfoMode = .Comments
    
    var viewers = [String]()
    var comments = [Comment]()
    var storyRef:StoryViewController?
    var postRef:PostViewController?
    //var item:StoryItem!
    var scrollViewRef:UIScrollView!
    
    var tableView:UITableView!
    
    var closeButton:UIBarButtonItem!
    var a:UIBarButtonItem!
    var navHeight:CGFloat!
    
    var header:CommentsHeaderView!
    
    var commentsRef:FIRDatabaseReference?
    var captionComment:Comment?
    
    var tapGesture:UITapGestureRecognizer!
    
    var shouldShowKeyboard:Bool = false
    
    var headerCell: CommentCell!
    
    var handleDismiss:(()->())!
    var popupDismiss:((_ animated:Bool)->())!
    
    func setInfoMode(_ mode:PostInfoMode) {
        if self.mode == mode { return }
        
        self.mode = mode
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        navHeight = 44.0 + 20.0
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = view.bounds
        
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.75)

        header = UINib(nibName: "CommentsHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentsHeaderView
        header.frame = CGRect(x: 0, y: 0 , width: view.frame.width, height: navHeight)
        header.closeHandler = handleDismiss
        header.moreHandler = actionHandler
        header.setMode = setInfoMode
        view.addSubview(header)
        
        let containerView = UIView(frame: CGRect(x: 0, y: navHeight, width: view.frame.width, height: view.frame.height - 50.0 - navHeight))
        view.addSubview(containerView)
        containerView.clipsToBounds = true
        
        tableView = UITableView(frame: CGRect(x: 0, y:0, width: containerView.frame.width, height: containerView.frame.height))
        let nib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "commentCell")
        
        let nib2 = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "userViewCell")
        
        headerCell = nib.instantiate(withOwner: nil, options: nil)[0] as! CommentCell
        //header.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 60)
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.20)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.backgroundColor = UIColor.clear//(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        tableView.tableHeaderView = UIView()
        tableView.showsVerticalScrollIndicator = false
        //tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 8))
        tableView.tableFooterView = UIView()
        
        
        containerView.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupItem(_ item: StoryItem) {
        //self.item = item
        self.header.setViewsLabel(count: item.viewers.count)
        
        header.setUserInfo(uid: item.getAuthorId())
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.viewers = item.getViewsList()
        self.comments = item.comments
        
        if item.getAuthorId() == mainStore.state.userState.uid {
            header.setCurrentUserMode(true)
            if self.comments.count > 0 {
                mode = .Comments
            } else {
                mode = .Viewers
            }
        } else {
            header.setCurrentUserMode(false)
            mode = .Comments
        }
        self.updateComments()
        
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/comments/\(item.getKey())")
        
        if let lastItem = item.comments.last {
            let lastKey = lastItem.getKey()
            let ts = lastItem.getDate().timeIntervalSince1970 * 1000
            commentsRef?.queryOrdered(byChild: "timestamp").queryStarting(atValue: ts).observe(.childAdded, with: { snapshot in
                
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                if key != lastKey {
                    let author = dict["author"] as! String
                    let text = dict["text"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                    item.addComment(comment)
                    self.comments = item.comments
                    self.updateComments()
                    self.scrollBottom(animated: true)
                }
            })
        } else {
            commentsRef?.observe(.childAdded, with: { snapshot in
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                let author = dict["author"] as! String
                let text = dict["text"] as! String
                let timestamp = dict["timestamp"] as! Double
                let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                item.addComment(comment)
                self.comments = item.comments
                self.updateComments()
                self.scrollBottom(animated: true)
            })
        }
    }
    
    fileprivate func updateComments() {
        self.header.setCommentsLabel(count: self.comments.count)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        commentsRef?.removeAllObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func authorTitleTapped(sender:UITapGestureRecognizer) {
        //showUser(uid: item.getAuthorId())
    }
    
    func showUser(uid:String) {
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = UserProfileViewController()
        controller.uid = uid
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch mode {
        case .Viewers:
            return viewers.count
        case .Comments:
            return comments.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch mode {
        case .Viewers:
            return 60
        case .Comments:
            let comment = comments[indexPath.row]
            let text = comment.getText()
            let width = tableView.frame.width - (12 + 12 + 10 + 32)
            let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightRegular))
            let height2 = size.height + 26 + 14 + 2 + 6  // +8 for some bio padding
            return height2
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mode {
        case .Viewers:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userViewCell", for: indexPath) as! UserViewCell
            cell.clearMode(true)
            cell.setupUser(uid: viewers[indexPath.row])
            let labelX = cell.usernameLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        case .Comments:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
            cell.setContent(comment: comments[indexPath.row])
            cell.authorTapped = showUser
            let labelX = cell.authorLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch mode {
        case .Viewers:
            break
        case .Comments:
            break
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func scrollBottom(animated:Bool) {
            if self.comments.count > 0 && mode == .Comments {
                let lastIndex = IndexPath(row: self.comments.count-1, section: 0)
                self.tableView.scrollToRow(at: lastIndex, at: UITableViewScrollPosition.bottom, animated: animated)
            }
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return false
        }
    }
    
    func actionHandler() {/*
        guard let item = self.item else { return }
        
        if item.getAuthorId() == mainStore.state.userState.uid {
            let alert = UIAlertController(title: "Delete post?", message: "This is permanent.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                UploadService.deleteItem(item: item, completion: { success in
                    if success {
                        self.popupDismiss(true)
                    }
                })
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { _ in}))
            self.present(sheet, animated: true, completion: nil)
        }
            */
    }

}


class tempViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}
