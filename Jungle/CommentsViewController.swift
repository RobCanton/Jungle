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
import ReSwift

enum PostInfoMode {
    case Viewers, Comments
}

protocol StoryCommentsProtocol: class {
    func dismissComments()
    func dismissStory()
    func replyToUser(_ username:String)
}

protocol CommentCellProtocol: class {
    func commentAuthorTapped(_ comment:Comment)
    func commentLikeTapped(_ comment:Comment, _ liked:Bool)
    func commentReplyTapped(_ comment:Comment, _ username:String)
}

protocol CommentsHeaderProtocol: class {
    func dismissFromHeader()
    func actionHandler()
    func setInfoMode(_ mode:PostInfoMode)
}


class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber  {
    
    var mode:PostInfoMode = .Comments
    
    var viewers = [String]()
    var comments = [Comment]()
    weak var itemRef:StoryItem?
    weak var delegate:StoryCommentsProtocol?
    
    var tableView:UITableView!
    
    var closeButton:UIBarButtonItem!
    var a:UIBarButtonItem!
    var navHeight:CGFloat!
    
    var header:CommentsHeaderView!
    
    var commentsRef:DatabaseReference?
    var viewsRef:DatabaseReference?
    
    var tapGesture:UITapGestureRecognizer!
    
    var shouldShowKeyboard:Bool = false
    
    func cleanup() {
        tableView = nil
        commentsRef = nil
        viewsRef = nil
        header = nil
        tapGesture = nil
        closeButton = nil
        viewers = []
        comments = []
    }
    
    deinit {
        print("Deinit >> CommentsViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    func newState(state: AppState) {
        tableView.reloadData()
    }
    
    func setup() {
        self.automaticallyAdjustsScrollViewInsets = false
        navHeight = 50.0
        
        view.backgroundColor = UIColor.white//(white: 0.0, alpha: 0.75)
        
        header = UINib(nibName: "CommentsHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentsHeaderView
        header.frame = CGRect(x: 0, y: 0 , width: view.frame.width, height: navHeight)
        header.delegate = self
        view.addSubview(header)
        
        header.applyShadow(radius: 4.0, opacity: 0.15, height: 0.0, shouldRasterize: false)
        
        let containerView = UIView(frame: CGRect(x: 0, y: navHeight, width: view.frame.width, height: view.frame.height - 50.0 - navHeight))
        view.addSubview(containerView)
        containerView.clipsToBounds = true
        
        tableView = UITableView(frame: CGRect(x: 0, y:0, width: containerView.frame.width, height: containerView.frame.height))
        let nib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "commentCell")
        
        let nib2 = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "userViewCell")
        
        //header.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 60)
        tableView.separatorColor = UIColor(white: 0.9, alpha: 1.0)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.backgroundColor = UIColor.white//(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        tableView.tableHeaderView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        //tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 8))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 70))
        
        containerView.addSubview(tableView)
    }
    
    func handleDismiss() {
        delegate?.dismissComments()
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
        mainStore.subscribe(self)
    }
    
    func setupItem(_ item: StoryItem) {
        if self.itemRef != nil {
            if self.itemRef!.key == item.key { return }
        }
        self.itemRef = item
        self.header.setViewsLabel(count: item.numViews)
        
        header.setUserInfo(uid: item.authorId)
        
        tableView.delegate = self
        tableView.dataSource = self
        observeViews()
        self.comments = item.comments
        
        let uid = mainStore.state.userState.uid
        
        header.postKey = item.key
        header.setCurrentUserMode(item.authorId == uid)
        
        self.updateComments()
        
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/comments/\(item.key)")
        
        if let lastItem = item.comments.last {
            let lastKey = lastItem.key
            let ts = lastItem.date.timeIntervalSince1970 * 1000
            commentsRef?.queryOrdered(byChild: "timestamp").queryStarting(atValue: ts).observe(.childAdded, with: { snapshot in
                
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                if key != lastKey {
                    let author = dict["author"] as! String
                    let text = dict["text"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp, numLikes: 0)
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
                let comment = Comment(key: key, author: author, text: text, timestamp: timestamp, numLikes: 0)
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
        subscribedRef = UserService.ref.child("uploads/subscribers/\(item.key)/\(uid)")
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
        if item.authorId == mainStore.state.userState.uid {
            viewsRef = UserService.ref.child("uploads/views/\(item.key)")
            viewsRef?.observe(.value, with: { snapshot in
                var viewers = [String]()
                for child in snapshot.children {
                    let childSnapshot = child as! DataSnapshot
                    viewers.append(childSnapshot.key)
                }
                self.viewers = viewers
                if self.mode == .Viewers {
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    var subscribedRef:DatabaseReference?
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mainStore.unsubscribe(self)
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
            let text = comment.text
            let width = tableView.frame.width - (12 + 12 + 10 + 32)
            let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightRegular))
            let height2 = size.height + 26 + 14 + 1  // +8 for some bio padding
            return height2
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mode {
        case .Viewers:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userViewCell", for: indexPath) as! UserViewCell
            cell.clearMode(false)
            cell.setupUser(uid: viewers[indexPath.row])
            cell.delegate = self
            let labelX = cell.usernameLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        case .Comments:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
            cell.setContent(comment: comments[indexPath.row], lightMode: false)
            cell.delegate = self
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
                guard let username = cell.authorLabel.text else { return }
                delegate?.replyToUser(username)
            }
            break
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let comment = self.comments[indexPath.row]
        
        var action:UITableViewRowAction!
        if comment.author == mainStore.state.userState.uid {
            action = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
                guard let item = self.itemRef else { return }
                let actionComment = self.comments[indexPath.row]
                
                let alert = UIAlertController(title: "Delete comment?", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    
                    UploadService.removeComment(postKey: item.key, commentKey: actionComment.key, completion: { success, commentKey in
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
                    UploadService.reportComment(itemKey: item.key, commentKey: actionComment.key, type: .SpamComment, completion: { success in })
                }))
                reportSheet.addAction(UIAlertAction(title: "Abusive Content", style: .destructive, handler: { _ in
                    UploadService.reportComment(itemKey: item.key, commentKey: actionComment.key, type: .AbusiveComment, completion: { success in })
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
    
    

}

extension CommentsViewController: CommentCellProtocol {
    func commentLikeTapped(_ comment: Comment, _ liked:Bool) {
        
    }
    
    func commentAuthorTapped(_ comment:Comment) {
    
    }
    
    func commentReplyTapped(_ comment:Comment, _ username:String) {
        
    }
}

extension CommentsViewController: CommentsHeaderProtocol {
    func dismissFromHeader() {
        handleDismiss()
    }

    func setInfoMode(_ mode:PostInfoMode) {
        if self.mode == mode { return }
        
        self.mode = mode
        self.tableView.reloadData()
    }
    
    func actionHandler() {
        guard let item = self.itemRef else { return }
        
        if item.authorId == mainStore.state.userState.uid {
            let alert = UIAlertController(title: "Delete post?", message: "This is permanent.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                UploadService.deleteItem(item: item, completion: { success in
                    if success {
                        self.delegate?.dismissStory()
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

extension CommentsViewController: UserCellProtocol {
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

class tempViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}
