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
    var itemRef:StoryItem?
    var scrollViewRef:UIScrollView!
    
    var tableView:UITableView!
    
    var closeButton:UIBarButtonItem!
    var a:UIBarButtonItem!
    var navHeight:CGFloat!
    
    var header:CommentsHeaderView!
    
    var commentsRef:FIRDatabaseReference?
    var viewsRef:FIRDatabaseReference?
    var captionComment:Comment?
    
    var tapGesture:UITapGestureRecognizer!
    
    var shouldShowKeyboard:Bool = false
    
    var replyToCommentHandler:((_ username:String)->())?
    
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
        tableView.keyboardDismissMode = .onDrag
        //tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 8))
        tableView.tableFooterView = UIView()
        
        
        containerView.addSubview(tableView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height > self.view.frame.size.height && scrollView.contentOffset.y == 0 {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupItem(_ item: StoryItem) {
        self.itemRef = item
        self.header.setViewsLabel(count: item.getNumViews())
        
        header.setUserInfo(uid: item.getAuthorId())
        
        tableView.delegate = self
        tableView.dataSource = self
        observeViews()
        self.comments = item.comments
        
        let uid = mainStore.state.userState.uid
        
        header.postKey = item.getKey()
        header.setCurrentUserMode(item.getAuthorId() == uid)
        mode = .Comments
        
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
            
            commentsRef?.queryOrdered(byChild: "timestamp").queryStarting(atValue: ts).observe(.childRemoved, with: { snapshot in
                item.removeComment(key: snapshot.key)
                self.comments = item.comments
                self.updateComments()
                self.scrollBottom(animated: true)
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
            
            commentsRef?.observe(.childRemoved, with: { snapshot in
                item.removeComment(key: snapshot.key)
                self.comments = item.comments
                self.updateComments()
                self.scrollBottom(animated: true)
            })
        }
        header.subscribed = nil
        subscribedRef?.removeAllObservers()
        subscribedRef = UserService.ref.child("uploads/subscribers/\(item.getKey())/\(uid)")
        subscribedRef?.observe(.value, with: { snapshot in
            self.header.setupNotificationsButton(snapshot.exists())
        })
    }
    
    
    func observeViews() {
        guard let item = self.itemRef else { return }
        self.viewers = []
        if self.mode == .Viewers {
            self.tableView.reloadData()
        }
        viewsRef?.removeAllObservers()
        if item.getAuthorId() == mainStore.state.userState.uid {
            viewsRef = UserService.ref.child("uploads/views/\(item.getKey())")
            viewsRef?.observe(.value, with: { snapshot in
                var viewers = [String]()
                for child in snapshot.children {
                    let childSnapshot = child as! FIRDataSnapshot
                    viewers.append(childSnapshot.key)
                }
                print("VIEWERS: \(viewers)")
                self.viewers = viewers
                if self.mode == .Viewers {
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    var subscribedRef:FIRDatabaseReference?
    
    fileprivate func updateComments() {
        self.header.setCommentsLabel(count: self.comments.count)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.navigationController?.delegate != nil {
            self.commentsRef?.removeAllObservers()
        }
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
            showUser(uid: viewers[indexPath.row])
            break
        case .Comments:
            if let cell = tableView.cellForRow(at: indexPath) as? CommentCell {
                guard let username = cell.user?.getUsername() else { return }
                replyToCommentHandler?(username)
            }
            break
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let comment = self.comments[indexPath.row]
        
        var action:UITableViewRowAction!
        if comment.getAuthor() == mainStore.state.userState.uid {
            action = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
                guard let item = self.itemRef else { return }
                let actionComment = self.comments[indexPath.row]
                
                let alert = UIAlertController(title: "Delete comment?", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    
                    UploadService.removeComment(postKey: item.getKey(), commentKey: actionComment.getKey(), completion: { success, commentKey in
                        if success {
                            item.removeComment(key: commentKey)
                            self.comments = item.comments
                            self.updateComments()
                            self.scrollBottom(animated: true)
                        }
                    })
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
            action.backgroundColor = errorColor.withAlphaComponent(0.75)
        } else {
            action = UITableViewRowAction(style: .destructive, title: "Report") { (rowAction, indexPath) in
                //TODO: Delete the row at indexPath here
                guard let item = self.itemRef else { return }
                let actionComment = self.comments[indexPath.row]
                
                let reportSheet = UIAlertController(title: nil, message: "Why are you reporting this comment?", preferredStyle: .actionSheet)
                reportSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                reportSheet.addAction(UIAlertAction(title: "Spam or Scam", style: .destructive, handler: { _ in
                    UploadService.reportComment(itemKey: item.getKey(), commentKey: actionComment.getKey(), type: .SpamComment, completion: { success in })
                }))
                reportSheet.addAction(UIAlertAction(title: "Abusive Content", style: .destructive, handler: { _ in
                    UploadService.reportComment(itemKey: item.getKey(), commentKey: actionComment.getKey(), type: .AbusiveComment, completion: { success in })
                }))
                self.present(reportSheet, animated: true, completion: nil)
            }
            action.backgroundColor = UIColor(white: 0.5, alpha: 0.75)
        }
        
        return [action]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
    
    func actionHandler() {
        guard let item = self.itemRef else { return }
        
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
            let reportSheet = UIAlertController(title: nil, message: "Why are you reporting this post?", preferredStyle: .actionSheet)
            reportSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            reportSheet.addAction(UIAlertAction(title: "It's Spam", style: .destructive, handler: { _ in
                UploadService.reportItem(item: item, type: .Spam, completion: { success in
                    
                })
            }))
            reportSheet.addAction(UIAlertAction(title: "It's inappropriate", style: .destructive, handler: { _ in
                UploadService.reportItem(item: item, type: .Inappropriate, completion: { success in
                    
                })
            }))
            self.present(reportSheet, animated: true, completion: nil)
        }
        
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
