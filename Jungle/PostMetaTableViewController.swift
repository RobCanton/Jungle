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

enum PostMetaTableMode:Int {
    case likes = 0
    case comments = 1
    case views = 2
}

class PostMetaTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ItemStateProtocol, StoreSubscriber {
    let userCellIdentifier = "userCell"
    var control:UISegmentedControl!
    var navHeight:CGFloat!
    var mode = PostMetaTableMode.likes
    var tableView:UITableView!
    var refreshControl: UIRefreshControl!
    
    var item:StoryItem!
    var likers = [String]()
    var viewers = [String]()
    var comments = [Comment]()
    
    var lastKey:String?
    
    var commentsRef:DatabaseReference?
    
    weak var itemStateController:ItemStateController!
    
    var previousDelegate:ItemStateProtocol?
    var limit:UInt = 25
    
    var keyboardUp = false
    var subscribedToPost = false
    
    
    var initialIndex:IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationBarBackdrop()
        navigationController?.navigationBar.tintColor = UIColor.black
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        view.backgroundColor = UIColor.white
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        control = UISegmentedControl(frame: CGRect(x: view.frame.width/4, y: 0, width: view.frame.width / 2, height: 30))
        control.insertSegment(withTitle: "Likes", at: 0, animated: false)
        control.insertSegment(withTitle: "Comments", at: 1, animated: false)
        control.addTarget(self, action: #selector(controlChange), for: .valueChanged)
        
        
        control.tintColor = UIColor.black
        navigationItem.titleView = control
        
        control.selectedSegmentIndex = mode.rawValue
        
        tableView = UITableView(frame:  CGRect(x: 0,y: navHeight, width: view.frame.width,height: view.frame.height - navHeight - 50.0))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.white
        tableView.keyboardDismissMode = .onDrag
        
        view.addSubview(tableView)
        
        let nib = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: userCellIdentifier)
        
        let nib2 = UINib(nibName: "CommentViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "commentCell")
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 12))
        tableView.reloadData()

        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.gray
        refreshControl.backgroundColor = UIColor.clear
        
        refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
        tableView.addSubview(self.refreshControl)
        
        fetchLikes()
        
        if item.authorId == mainStore.state.userState.uid {
            control.insertSegment(withTitle: "Views", at: 2, animated: false)
            fetchViews()
        }
        
        view.addSubview(commentBar)
        commentBar.darkMode()
        commentBar.delegate = self
        commentBar.textField.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        previousDelegate = itemStateController.delegate
        itemStateController.delegate = self
        
        self.comments = item.comments
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
        tableView.reloadData()
    }
    
    func handleRefresh() {
        let firstComment = comments[0]
        lastKey = firstComment.key
        itemStateController.retrievePreviousComments()
    }
    
    func controlChange(_ target:UISegmentedControl) {
        switch target.selectedSegmentIndex {
        case 0:
            mode = .likes
            commentBar.isHidden = true
            commentBar.isUserInteractionEnabled = false
            break
        case 1:
            mode = .comments
            commentBar.isHidden = false
            commentBar.isUserInteractionEnabled = true
            break
        case 2:
            mode = .views
            commentBar.isHidden = true
            commentBar.isUserInteractionEnabled = false
            break
        default:
            break
        }
        
        tableView.reloadData()
    }
    
    func itemStateDidChange(likedStatus: Bool) {
        self.commentBar.setLikedStatus(likedStatus, animated: false)
    }
    
    func itemStateDidChange(numLikes: Int) {

    }
    
    func itemStateDidChange(numComments: Int) {
        
    }
    
    func itemStateDidChange(comments: [Comment]) {
        //self.commentsView.setTableComments(comments: comments, animated: true)
        self.comments = comments
        self.tableView.reloadData()
        scrollBottom(animated: true)
    }
    
    func itemStateDidChange(comments: [Comment], didRetrievePreviousComments: Bool) {
        self.refreshControl.endRefreshing()
        if didRetrievePreviousComments {
            self.comments = comments
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
                    tableView.scrollToRow(at: scrollToIndex!, at: .middle, animated: false)
                    lastKey = nil
                    scrollToIndex = nil
                }
                
            }
        } else {
            self.refreshControl.isEnabled = false
            self.refreshControl.removeFromSuperview()
        }
    }
    
    func itemStateDidChange(subscribed: Bool) {
        
    }
    
    func itemDownloading() {

    }
    
    func itemDownloaded() {

    }
    
    func scrollBottom(animated:Bool) {
        if comments.count > 0 && mode == .comments {
            let lastIndex = IndexPath(row: comments.count-1, section: 0)
            self.tableView.scrollToRow(at: lastIndex, at: UITableViewScrollPosition.bottom, animated: animated)
        }
    }

    func fetchLikes() {
        let ref = Database.database().reference()
        ref.child("uploads/likes/\(item.key)").observeSingleEvent(of: .value, with: { snapshot in
            var uids = [String]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                uids.append(childSnap.key)
            }
            self.likers = uids
            self.tableView.reloadData()
        })
    }
    
    func fetchViews() {
        let ref = Database.database().reference()
        ref.child("uploads/views/\(item.key)").observeSingleEvent(of: .value, with: { snapshot in
            var uids = [String]()
            for child in snapshot.children {
                let childSnap = child as! DataSnapshot
                uids.append(childSnap.key)
            }
            self.viewers = uids
            self.tableView.reloadData()
        })
    }
    

    
    func commentsChanged(comments: [Comment], didRetrievePreviousComments:Bool) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch mode {
        case .likes:
            return likers.count
        case .views:
            return viewers.count
        case .comments:
            return comments.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch mode {
        case .likes:
            return 60
        case .views:
            return 60
        case .comments:
            let comment = comments[indexPath.row]
            let text = comment.text
            let width = tableView.frame.width - (12 + 8 + 12 + 32)
            let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular))
            let height2 = size.height + 12 + 12 + 18 + 4   // +8 for some bio padding
            return height2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mode {
        case .likes:
            let cell = tableView.dequeueReusableCell(withIdentifier: userCellIdentifier, for: indexPath) as! UserViewCell
            cell.setupUser(uid: likers[indexPath.row])
            cell.delegate = self
            let labelX = cell.usernameLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        case .views:
            let cell = tableView.dequeueReusableCell(withIdentifier: userCellIdentifier, for: indexPath) as! UserViewCell
            cell.setupUser(uid: viewers[indexPath.row])
            cell.delegate = self
            let labelX = cell.usernameLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        case .comments:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
            cell.delegate = self
            cell.shadow = false
            cell.setContent(comment: comments[indexPath.row], lightMode: false)
            cell.authorLabel.textColor = UIColor.black
            cell.commentLabel.textColor = UIColor.black
            cell.timeLabel.textColor = UIColor.gray
            
            cell.timeLabel.isHidden = false
            
            let labelX = cell.authorLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            
            return cell
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch mode {
        case .likes:
            let controller = UserProfileViewController()
            controller.uid = likers[indexPath.row]
            self.navigationController?.pushViewController(controller, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)

            break
        case .views:
            let controller = UserProfileViewController()
            controller.uid = viewers[indexPath.row]
            self.navigationController?.pushViewController(controller, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)

            break
        case .comments:
            let cell = tableView.cellForRow(at: indexPath) as! CommentCell
            if let username = cell.authorLabel.text, username != "" {
                commentBar.textField.text = "@\(username) "
                commentBar.textField.becomeFirstResponder()
            }
            tableView.deselectRow(at: indexPath, animated: true)
            
            break
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let comment = self.comments[indexPath.row]
        
        var action:UITableViewRowAction!
        if comment.author == mainStore.state.userState.uid {
            action = UITableViewRowAction(style: .normal, title: "Delete") { (rowAction, indexPath) in
                guard let item = self.item else { return }
                let actionComment = self.comments[indexPath.row]
                
                let alert = UIAlertController(title: "Delete comment?", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    
                    UploadService.removeComment(postKey: item.key, commentKey: actionComment.key, completion: { success, commentKey in
                        if success {
                            item.removeComment(key: commentKey)
                            self.comments = item.comments
                            self.tableView.reloadData()
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
    func showAuthor(_ uid: String) {
        let controller = UserProfileViewController()
        controller.uid = uid
        self.navigationController?.pushViewController(controller, animated: true)
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
        
        self.commentBar.likeButton.isUserInteractionEnabled = false
        self.commentBar.moreButton.isUserInteractionEnabled = false
        self.commentBar.sendButton.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.view.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)
            
            self.commentBar.sendButton.alpha = 1.0
            self.commentBar.activityIndicator.alpha = 1.0

        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false

        print("keyboardWillDisappear")
        self.commentBar.likeButton.isUserInteractionEnabled = true
        self.commentBar.moreButton.isUserInteractionEnabled = true
        self.commentBar.sendButton.isUserInteractionEnabled = false

        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
            let height = self.view.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewStart = height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)

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
