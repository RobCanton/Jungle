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

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    var comments = [Comment]()
    var storyRef:StoryViewController!
    var item:StoryItem!
    
    var tableView:UITableView!
    
    var containerRef:ContainerViewController?
    
    var closeButton:UIBarButtonItem!
    var a:UIBarButtonItem!
    var navHeight:CGFloat!
    
    var header:CommentsHeaderView!
    var commentBar:CommentBar!
    
    var commentsRef:FIRDatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0

        header = UINib(nibName: "CommentsHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentsHeaderView
        header.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight)
        view.addSubview(header)
        
        header.closeHandler = dismissHandle
        
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        
        tableView = UITableView(frame: CGRect(x: 0, y: navHeight, width: view.frame.width, height: view.frame.height - navHeight))
        let nib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "commentCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor(white: 0.1, alpha: 0)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.backgroundColor = UIColor.clear//(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        tableView.tableHeaderView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 8))
        tableView.tableFooterView = UIView()
        
        self.view.addSubview(tableView)
        
        self.comments = item.comments
        self.tableView.reloadData()
        
        commentBar = UINib(nibName: "CommentBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentBar
        commentBar.frame = CGRect(x: 0, y: view.frame.height - 50.0, width: view.frame.width, height: 50.0)
        commentBar.textField.delegate = self
        commentBar.sendHandler = sendComment

        self.view.addSubview(commentBar)
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/\(item.getKey())/comments")
        
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
                    self.item.addComment(comment)
                    self.comments = self.item.comments
                    self.tableView.reloadData()
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
                self.item.addComment(comment)
                self.comments = self.item.comments
                self.tableView.reloadData()
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        commentsRef?.removeAllObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    func dismissHandle() {
        storyRef.fadeInDetails()
        storyRef.commentsActive = false
        self.dismiss(animated: true, completion: nil)
    }
    
    func showUser() {
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = tempViewController()
        controller.title = title
        controller.view.backgroundColor = UIColor.white
        self.navigationController?.pushViewController(controller, animated: true)
    }
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let comment = comments[indexPath.row]
        let text = comment.getText()
        let width = tableView.frame.width - (12 + 10 + 8 + 32)
        let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular))
        let height2 = size.height + 26 + 14  // +8 for some bio padding
        return height2
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
        cell.setContent(comment: comments[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CommentCell
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func keyboardWillAppear(notification: NSNotification){

        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        self.commentBar.sendButton.isEnabled = true
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.view.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)

            self.commentBar.sendButton.alpha = 1.0
            
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){

        self.commentBar.sendButton.isEnabled = false

        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
            let height = self.view.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewStart = height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)

        })
        
    }
    
    func sendComment(_ comment: String) {
        guard let item = self.item else { return }
        print("SEND COMMENT: \(comment)")
        UploadService.addComment(post: item, comment: comment)
    }

}

extension CommentsViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if !text.isEmpty {
                textField.text = ""
                sendComment(text)
            }
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 140 // Bool
    }
}

class tempViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        globalContainerRef?.statusBar(hide: false)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        globalContainerRef?.statusBar(hide: true)
        super.viewWillDisappear(animated)
    }
}
