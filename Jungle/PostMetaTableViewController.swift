//
//  PostMetaTableViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-22.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Segmentio
import Firebase
import ReSwift
import SwiftMessages

enum PostMetaTableMode:Int {
    case likes = 0
    case comments = 1
    case views = 2
}

enum CommentsSortedBy {
    case popularity
    case date
}

class PostMetaTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ItemStateProtocol, StoreSubscriber {
    let userCellIdentifier = "userCell"
    var navHeight:CGFloat!

    var tableView:UITableView!
    var refreshControl: UIRefreshControl!
    
    var item:StoryItem!

    var viewers = [String]()
    var comments = [Comment]()
    var messageWrapper = SwiftMessages()
    
    var lastKey:String?
    
    var commentsRef:DatabaseReference?
    
    weak var itemStateController:ItemStateController!
    
    var previousDelegate:ItemStateProtocol?
    var limit:UInt = 16
    
    var keyboardUp = false
    var subscribedToPost = false
    
    
    var initialIndex:IndexPath?
    
    var headerView:UIView!
    var viewsLabel:UILabel!
    var anonLikesLabel:UILabel!
    
    var loadMore:LoadMoreTableView!
    var titleButton:UIButton!
    var notificationsButton:UIBarButtonItem!
    var notificationsMutedButton:UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationBarBackdrop()
        navigationController?.navigationBar.tintColor = UIColor.black
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        view.backgroundColor = UIColor.white
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        titleButton =  UIButton(type: .custom)
        titleButton.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        titleButton.setTitleColor(UIColor.black, for: .normal)
        titleButton.setTitleColor(UIColor.gray, for: .focused)
        titleButton.setTitleColor(UIColor.gray, for: .highlighted)
        titleButton.setTitleColor(UIColor.gray, for: .selected)
        titleButton.setTitle("Comments", for: UIControlState.normal)

        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightMedium)
        titleButton.semanticContentAttribute = .forceRightToLeft
        titleButton.setImage(UIImage(named:"sortdownblack"), for: .normal)
        titleButton.setImage(UIImage(named:"sortdowngray"), for: .focused)
        titleButton.setImage(UIImage(named:"sortdowngray"), for: .highlighted)
        titleButton.setImage(UIImage(named:"sortdowngray"), for: .selected)
        titleButton.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 0)
        titleButton.addTarget(self, action: #selector(showSortingOptions), for: .touchUpInside)
        navigationItem.titleView = titleButton
        
        
        tableView = UITableView(frame:  CGRect(x: 0,y: navHeight, width: view.frame.width,height: view.frame.height - navHeight - 50.0))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(white:0.96, alpha: 1.0)
        tableView.keyboardDismissMode = .onDrag
        
        
        view.addSubview(tableView)
        
        let nib = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: userCellIdentifier)
        
        let nib2 = UINib(nibName: "CommentViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "commentCell")
        
        loadMore = UINib(nibName: "LoadMoreTableView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LoadMoreTableView
        loadMore.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60)
        loadMore.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(loadMoreComments))
        loadMore.addGestureRecognizer(tap)

        notificationsButton = UIBarButtonItem(image: UIImage(named:"notifications"), style: .plain, target: self, action: #selector(togglePostNotifications))
        notificationsButton.tintColor = UIColor.black
        notificationsMutedButton = UIBarButtonItem(image: UIImage(named:"notifications_muted"), style: .plain, target: self, action: #selector(togglePostNotifications))
        notificationsMutedButton.tintColor = UIColor.black
        
        itemStateDidChange(subscribed: itemStateController.isSubscribed)
        
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 32))
        headerView.backgroundColor = UIColor.white
        
        anonLikesLabel  = UILabel(frame: headerView.bounds)
        anonLikesLabel.textColor = UIColor.black
        anonLikesLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightSemibold)
        anonLikesLabel.text = ""
        anonLikesLabel.textAlignment = .center
        headerView.addSubview(anonLikesLabel)
        

        self.tableView.tableHeaderView = comments.count < item.numComments ? loadMore : UIView()

        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 250))
        
        tableView.reloadData()

        
        view.addSubview(commentBar)
        commentBar.darkMode()
        commentBar.showCurrentAnonMode()
        commentBar.likeButton.removeFromSuperview()
        commentBar.moreButton.removeFromSuperview()
        commentBar.delegate = self
        commentBar.textField.delegate = self
        
        observeTopComments()
        
    }
    
    func loadMoreComments() {
        print("Load more comments")
        loadMore.startLoadAnimation()
        handleRefresh()
    }
    
    func sortComments() {
        switch sort {
        case .date:
            self.titleButton.setTitle("Comments", for: .normal)
            self.comments = item.comments
            print("NUM COMMENTS: \(self.comments.count) | TOTAL: \(item.numComments)")

            self.tableView.tableHeaderView = comments.count < item.numComments ? loadMore : UIView()
            self.tableView.tableFooterView = UIView()
            
            break
        case .popularity:
            self.titleButton.setTitle("Top Comments", for: .normal)

            self.tableView.tableHeaderView = UIView()
            self.tableView.tableFooterView = topComments.count < item.numComments ? loadMore : UIView()

            break
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        previousDelegate = itemStateController.delegate
        itemStateController.delegate = self
        

        sortComments()
        
        self.tableView.reloadData()
        
        
        if let index = initialIndex {
            print("has initial index")
            print("initial: \(index.row) | tableRows: \(tableView.numberOfRows(inSection: 0))")
            if index.row < tableView.numberOfRows(inSection: 0) {
                print("scroll to initial index")
                tableView.scrollToRow(at: index, at: .top, animated: false)
            }
            initialIndex = nil
        } else{
            scrollBottom(animated: false)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mainStore.subscribe(self)
        self.setNeedsStatusBarAppearanceUpdate()
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        itemStateController.delegate = previousDelegate
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    func newState(state: AppState) {
       
    }
    
    var sort:CommentsSortedBy = .date
    var topComments = [Comment]()
    
    func showSortingOptions() {
        
        let alert = UIAlertController(title: "Sort by...", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let dateStr = sort == .date ?  "• Date" :  "Date"
        let popularitryStr = sort == .popularity ?  "• Popularity" :  "Popularity"
        
        alert.addAction(UIAlertAction(title: dateStr, style: .default, handler: { _ in
            self.sort = .date
            self.sortComments()
            self.tableView.reloadData()
            self.scrollBottom(animated: false)
        }))
        
        alert.addAction(UIAlertAction(title: popularitryStr, style: .default, handler: { _ in
            self.sort = .popularity
            self.sortComments()
            self.tableView.reloadData()
            self.scrollToTop(animated: false)
        }))

        
        self.present(alert, animated: true, completion: nil)
    }
    
    func togglePostNotifications() {
        let subscribed = itemStateController.isSubscribed
        UploadService.subscribeToPost(withKey: self.item.key, subscribe: !subscribed)
    }
    
    func observeTopComments() {
        guard let item = self.item else { return }
        //self.delegate?.itemStateDidChange(comments: item.comments)
        topComments = []
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/comments/\(item.key)")
        
        commentsRef?.queryOrdered(byChild: "likes").queryLimited(toLast: limit).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var commentBatch = [Comment]()
                
                for commentChild in snapshot.children {
                    let commentSnap = commentChild as! DataSnapshot
                    let key = commentSnap.key
                    let dict = commentSnap.value as! [String:Any]
                    let author = dict["author"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    let text = dict["text"] as! String
                    
                    var numLikes = 0
                    if let likes = dict["likes"] as? Int {
                        numLikes = likes
                    }
                    
                    if !self.topCommentsContains(key: key) {
                        
                        if let anon = dict["anon"] as? [String:Any] {
                            let adjective = anon["adjective"] as! String
                            let animal = anon["animal"] as! String
                            let color = anon["color"] as! String
                            let comment = AnonymousComment(key: key, author: author, text: text, timestamp: timestamp, numLikes:numLikes, adjective: adjective, animal: animal, colorHexcode: color)
                            commentBatch.insert(comment, at: 0)
                        } else {
                            let comment = Comment(key: key, author: author, text: text, timestamp: timestamp, numLikes:numLikes)
                            commentBatch.insert(comment, at: 0)
                            
                        }
                    }
                }
                
                if commentBatch.count > 0 {
                    self.topComments.append(contentsOf: commentBatch)
                }
            }
            
            self.sortComments()
            self.tableView.reloadData()
            self.loadMore.stopLoadAnimation()
            
        })
        
    }
    
    func topCommentsContains(key:String) -> Bool {
        for comment in topComments {
            if comment.key == key {
                return true
            }
        }
        
        return false
    }
    
    func retrievePreviousTopComments() {
        guard let item = self.item else { return }
        if topComments.count == 0 { return }
        let oldestComment = topComments[0]
        limit += limit
        commentsRef?.queryOrdered(byChild: "likes").queryLimited(toLast: limit).queryEnding(atValue: oldestComment.numLikes + 1).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var commentBatch = [Comment]()
                
                for commentChild in snapshot.children {
                    let commentSnap = commentChild as! DataSnapshot
                    let key = commentSnap.key
                    let dict = commentSnap.value as! [String:Any]
                    let author = dict["author"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    let text = dict["text"] as! String
                    
                    var numLikes = 0
                    if let likes = dict["likes"] as? Int {
                        numLikes = likes
                    }
                    
                    if !self.topCommentsContains(key: key) {
                        
                        if let anon = dict["anon"] as? [String:Any] {
                            let adjective = anon["adjective"] as! String
                            let animal = anon["animal"] as! String
                            let color = anon["color"] as! String
                            let comment = AnonymousComment(key: key, author: author, text: text, timestamp: timestamp, numLikes:numLikes, adjective: adjective, animal: animal, colorHexcode: color)
                            commentBatch.insert(comment, at: 0)
                        } else {
                            let comment = Comment(key: key, author: author, text: text, timestamp: timestamp, numLikes:numLikes)
                            commentBatch.insert(comment, at: 0)
                            
                        }
                        
                    }
                    
                }
                
                if commentBatch.count > 0 {
                    self.topComments.append(contentsOf: commentBatch)//.insert(contentsOf: commentBatch, at: 0)
                    //self.delegate?.itemStateDidChange(comments: item.comments, didRetrievePreviousComments: true)
                }
            }

            self.sortComments()
            self.tableView.reloadData()
            self.loadMore.stopLoadAnimation()
            
        })
    }

    
    func handleRefresh() {
        if sort == .date {
            let firstComment = comments[0]
            lastKey = firstComment.key
            itemStateController.retrievePreviousComments()
        } else {
            self.retrievePreviousTopComments()
        }
        
    }
    
    func itemStateDidChange(likedStatus: Bool) {
        self.commentBar.setLikedStatus(likedStatus, animated: false)
    }
    
    func itemStateDidChange(numLikes: Int) {

    }
    
    func itemStateDidChange(numComments: Int) {
        
    }
    
    func itemStateDidChange(comments: [Comment]) {
        
       sortComments()
        
        self.tableView.reloadData()
        scrollBottom(animated: false)
    }
    
    func itemStateDidChange(comments: [Comment], didRetrievePreviousComments: Bool) {
        
        loadMore.stopLoadAnimation()
        
        if didRetrievePreviousComments {
            
            sortComments()
            
            self.tableView.reloadData()
            if lastKey != nil {
                var scrollToIndex:IndexPath?
                for i in 0..<comments.count {
                    if comments[i].key == lastKey {
                        scrollToIndex = IndexPath(row: i, section: 0)
                        break
                    }
                }
                if scrollToIndex != nil {
                    tableView.scrollToRow(at: scrollToIndex!, at: .bottom, animated: false)
                    lastKey = nil
                    scrollToIndex = nil
                }
                
            }
        } else {
            //self.refreshControl.isEnabled = false
            //self.refreshControl.removeFromSuperview()
        }
    }
    
    func itemStateDidChange(subscribed: Bool) {
        if subscribed {
            self.navigationItem.rightBarButtonItem = notificationsButton
        } else {
            self.navigationItem.rightBarButtonItem = notificationsMutedButton
        }
    }
    
    func itemDownloading() {

    }
    
    func itemDownloaded() {

    }
    
    func scrollBottom(animated:Bool) {
        if comments.count > 0 && sort == .date {
            let lastIndex = IndexPath(row: comments.count-1, section: 0)
            self.tableView.scrollToRow(at: lastIndex, at: UITableViewScrollPosition.bottom, animated: animated)
        }
    }
    
    func scrollToTop(animated:Bool) {
        if comments.count > 0 && sort == .popularity {
            let firstIndex = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: firstIndex, at: UITableViewScrollPosition.top, animated: animated)
        }
    }

    
    

    
    func commentsChanged(comments: [Comment], didRetrievePreviousComments:Bool) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sort == .popularity {
            return topComments.count
        }
        return comments.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        var comment:Comment!
        if sort == .popularity {
            comment = topComments[indexPath.row]
        } else {
            comment = comments[indexPath.row]
        }
        
        let text = comment.text
        let width = tableView.frame.width - (8 + 36 + 8 + 48)
        let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightRegular))
        let height2 = size.height + 12 + 6 + 18 + 4 + 22 + 2 // +8 for some bio padding
        return height2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! DetailedCommentCell
        var comment:Comment!
        if sort == .popularity {
            comment = topComments[indexPath.row]
        } else {
            comment = comments[indexPath.row]
        }
        cell.isOP = comment.author == item.authorId

        cell.delegate = self
        cell.setContent(itemKey: item.key, comment: comment)
        
        cell.timeLabel.isHidden = false
        
        let labelX = cell.authorLabel.frame.origin.x
        cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let comment = self.comments[indexPath.row]
        
        var action:UITableViewRowAction!
        if isCurrentUserId(id: comment.author) {
            action = UITableViewRowAction(style: .normal, title: "Remove") { (rowAction, indexPath) in
                self.showDeleteCommentAlert(self.comments[indexPath.row])
            }
            action.backgroundColor = errorColor.withAlphaComponent(0.75)
        } else {
            action = UITableViewRowAction(style: .destructive, title: "Report") { (rowAction, indexPath) in
                //TODO: Delete the row at indexPath here
                guard let item = self.item else { return }
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
            action.backgroundColor = UIColor(white: 0.5, alpha: 1.0)
        }
        
        return [action]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let commentCell = cell as? DetailedCommentCell {
            commentCell.reset()
        }
    }
    
    
    
    lazy var commentBar: CommentItemBar = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        var view: CommentItemBar = UINib(nibName: "CommentItemBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentItemBar
        view.frame = CGRect(x: 0, y: height - 50.0, width: width, height: 50.0)
        return view
    }()
}

extension PostMetaTableViewController: UserCellProtocol {
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

extension PostMetaTableViewController: CommentCellProtocol {
    
    func commentAuthorTapped(_ comment:Comment) {
        if let _ = comment as? AnonymousComment {
            showAnonOptions(comment.author)
        } else {
            let controller = UserProfileViewController()
            controller.uid = comment.author
            self.navigationController?.pushViewController(controller, animated: true)

        }
    }
    
    func commentLikeTapped(_ comment:Comment, _ liked:Bool) {

        let ref = UserService.ref.child("uploads/commentLikes/\(item.key)/\(comment.key)/\(userState.uid)")
        
        if liked {
            ref.setValue(true) { error, ref in
                if error == nil {
                    print("Comment Liked")
                } else {
                    print("Error liking comment")
                }
            }
        } else {
            ref.removeValue() { error, ref in
                if error == nil {
                    print("Comment Unliked")
                } else {
                    print("Error unliking comment")
                }
            }
        }
        
        
    }
    
    func commentReplyTapped(_ comment:Comment, _ username:String) {

        if isCurrentUserId(id: comment.author) {
            showDeleteCommentAlert(comment)
        } else {
            commentBar.textField.text = "@\(username) "
            commentBar.textField.becomeFirstResponder()
        }

    }
    
    func showDeleteCommentAlert(_ comment:Comment) {
        let alert = UIAlertController(title: "Remove comment?", message: "\"\(comment.text)\"", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
            
            UploadService.removeComment(postKey: self.item.key, commentKey: comment.key, completion: { success, commentKey in
                if success {
                    self.item.removeComment(key: commentKey)
                    self.comments = self.item.comments
                    
                    var removeIndex:Int?
                    for i in 0..<self.topComments.count {
                        if self.topComments[i].key == commentKey {
                            removeIndex = i
                            break
                        }
                    }
                    
                    if removeIndex != nil {
                        self.topComments.remove(at: removeIndex!)
                    }
                    
                    self.tableView.reloadData()
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAnonOptions(_ aid: String) {

        if let my_aid = userState.anonID, my_aid != aid {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in

            }
            actionSheet.addAction(cancelActionButton)
            
//            let messageAction: UIAlertAction = UIAlertAction(title: "Send Message", style: .default) { action -> Void in
//                
//            }
//            actionSheet.addAction(messageAction)
            
            let blockAction: UIAlertAction = UIAlertAction(title: "Block", style: .destructive) { action -> Void in
                UserService.blockAnonUser(aid: aid) { success in }
            }
            
            actionSheet.addAction(blockAction)
            
            let reportAction: UIAlertAction = UIAlertAction(title: "Report User", style: .destructive) { action -> Void in
                let reportSheet = UIAlertController(title: nil, message: "Why are you reporting this user?", preferredStyle: .actionSheet)
                reportSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                reportSheet.addAction(UIAlertAction(title: "Harassment", style: .destructive, handler: { _ in
                    UserService.reportAnonUser(aid: aid, type: .Harassment, completion: { success in })
                }))
                reportSheet.addAction(UIAlertAction(title: "Bot", style: .destructive, handler: { _ in
                    UserService.reportAnonUser(aid: aid, type: .Bot, completion: { success in })
                }))
                self.present(reportSheet, animated: true, completion: nil)
            }
            
            actionSheet.addAction(reportAction)
            
            self.present(actionSheet, animated: true, completion: nil)
            
        }
    }
}

extension PostMetaTableViewController: CommentItemBarProtocol {
    func sendComment(_ comment:String) {
        commentBar.setBusyState(true)

        UploadService.addComment(post: item, comment: comment) { success in
            self.commentBar.setBusyState(false)
        }
    }
    func toggleLike(_ like:Bool) {
        
        if like {
            UploadService.addLike(post: item)
            item.addLike(mainStore.state.userState.uid)
        } else {
            UploadService.removeLike(post: item)
            item.removeLike(mainStore.state.userState.uid)
        }
    }
    
    
    func editCaption() {

    }
    func showMore() {
        
    }
    
    func keyboardWillAppear(notification: NSNotification){
        keyboardUp = true

        print("keyboardWillAppear")
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        self.commentBar.setKeyboardUp(true)
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.view.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)
            
            self.commentBar.sendButton.alpha = 1.0
            self.commentBar.activityIndicator.alpha = 1.0
            self.commentBar.userImageView.alpha = userState.anonMode ? 0.6 : 1.0

        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false

        print("keyboardWillDisappear")
        self.commentBar.setKeyboardUp(false)

        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
            let height = self.view.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewStart = height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)
            self.commentBar.userImageView.alpha = 0.35
            self.commentBar.sendButton.alpha = 0.5
            self.commentBar.activityIndicator.alpha = 0.0
        })
        
    }
}

extension PostMetaTableViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 140 // Bool
    }
}
