//
//  CommentsOverlayTableView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//


import UIKit

protocol CommentsTableProtocol:class {
    func showUser(_ uid:String)
    func refreshPulled()
    func showPostComments(_ indexPath:IndexPath?)
    func showAnonOptions(_ aid:String, _ anonName:String)
}

class CommentsOverlayTableView: UIView, UITableViewDelegate, UITableViewDataSource, CommentCellProtocol {
    
    var comments = [Comment]()
    
    var tableView:UITableView!
    var divider:UIView!
    var hasCaption = false
    
    
    weak var delegate:CommentsTableProtocol?
    weak var itemRef:StoryItem?
    
    func cleanUp() {
        comments = [Comment]()
        tableView.reloadData()
        divider.isHidden = true
        delegate = nil
    }
    
    func showAuthor(_ uid: String) {
        delegate?.showUser(uid)
    }
    
    func commentAuthorTapped(_ comment:Comment) {
        if let anon = comment as? AnonymousComment {
            delegate?.showAnonOptions(anon.author, anon.anonName)
        } else {
            delegate?.showUser(comment.author)
        }
    }
    
    func commentLikeTapped(_ comment:Comment, _ liked:Bool) {
        
    }
    
    func commentReplyTapped(_ comment:Comment, _ username:String) {
        
    }
    
    func commentMentionTapped(_ mention: String) {
        
        for comment in comments {
            if let anon = comment as? AnonymousComment {
                if anon.anonName == mention {
                    delegate?.showAnonOptions(anon.author, anon.anonName)
                    return
                }
            }
        }
        
        let controller = UserProfileViewController()
        controller.username = mention
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    var header:UIView!
    var viewMore:LoadMoreCommentsOverlayView!
    
    func setup() {
        self.clipsToBounds = true
        let gradient = CAGradientLayer()
        
        gradient.frame = self.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.075, 1.0]
        self.layer.mask = gradient
        
        tableView = UITableView(frame: self.bounds)
        
        
        let nib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "commentCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor(white: 0.1, alpha: 0)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.backgroundColor = UIColor.clear//(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0))
        header.backgroundColor = UIColor.green

        viewMore = UINib(nibName: "LoadMoreCommentsOverlayView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LoadMoreCommentsOverlayView
        viewMore.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60)
        viewMore.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleRefresh))
        viewMore.addGestureRecognizer(tap)
        
        tableView.tableHeaderView = viewMore
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        
        self.addSubview(tableView)
        
        divider = UIView(frame: CGRect(x: 8,y: frame.height-1, width: frame.width-16, height: 1))
        divider.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
        divider.isHidden = true
        self.addSubview(divider)
        
        reloadTable()
        scrollBottom(animated: false)

    }
    
    var lastKey:String?
    
    func handleRefresh() {
        viewMore.startLoadAnimation()
        delegate?.refreshPulled()
        let firstComment = comments[0]
        lastKey = firstComment.key
    }
    
    func setTableComments(item:StoryItem, comments:[Comment], animated:Bool, delayViewMore:Bool)
    {
        //if delayViewMore {
            //viewMore.delay()
        //}
        viewMore.stopLoadAnimation()
        self.itemRef = item
        self.comments = comments
        divider.isHidden = hasCaption || comments.count == 0
        reloadTable()
        scrollBottom(animated: animated)
    }
    
    func endRefreshing(comments: [Comment], didRetrievePreviousComments: Bool) {
        print("endRefreshing")
        
        if didRetrievePreviousComments {
            print("didRetrievePreviousComments")
            self.comments = comments
            divider.isHidden = hasCaption || comments.count == 0
            reloadTable()
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
            print("DID NOT: RetrievePreviousComments")
            viewMore.stopLoadAnimation()
        }
    }
    
    func reloadTable() {
        
        if comments.count >= 6 {
            header.frame = CGRect(x: 0, y: 0, width: header.frame.width, height: 30)
        } else {
            header.frame = CGRect(x: 0, y: 0, width: header.frame.width, height:0)
        }
        
        if let item = itemRef {
            tableView.tableHeaderView = comments.count < item.numComments && comments.count >= 16 ? viewMore : UIView(frame:CGRect(x: 0, y: 0, width: tableView.frame.width, height: 12.0))
        } else {
            tableView.tableHeaderView = UIView(frame:CGRect(x: 0, y: 0, width: tableView.frame.width, height: 12.0))
        }
        
        tableView.reloadData()
        
        let containerHeight = self.bounds.height
        let tableHeight = tableView.contentSize.height
        
        if tableHeight < containerHeight {
            tableView.frame.origin.y = containerHeight - tableHeight
            tableView.isScrollEnabled = false
        } else {
            tableView.frame.origin.y = 0
            tableView.isScrollEnabled = true
        }
    }
    
    func getTableHeight() -> CGFloat {
        let containerHeight = self.bounds.height
        let tableHeight = tableView.contentSize.height
        if tableHeight > containerHeight {
            return containerHeight
        }
        return tableHeight
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let comment = comments[indexPath.row]
        let text = comment.text
        let width = tableView.frame.width - (8 + 8 + 10 + 32)
        let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular))
        let height2 = size.height + 26 + 2   // +8 for some bio padding
        return height2
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
        let comment = comments[indexPath.row]
        if let item = itemRef {
            cell.isOP = comment.author == item.authorId
        } else {
            cell.isOP = false
        }
        
        cell.setContent(comment: comment, lightMode: true)
        cell.delegate = self
        
        if showTimeStamps {
            cell.timeLabel.isHidden = false
        } else {
            cell.timeLabel.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CommentCell

        let comment = comments[indexPath.row]
        delegate?.showPostComments(indexPath)
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func scrollBottom(animated:Bool) {
        if comments.count > 0 {
            let lastIndex = IndexPath(row: comments.count-1, section: 0)
            self.tableView.scrollToRow(at: lastIndex, at: UITableViewScrollPosition.bottom, animated: animated)
        }
    }
    
    var showTimeStamps = false
    
    func showTimeLabels(visible:Bool) {
        showTimeStamps = visible
        for cell in tableView.visibleCells {
            let c = cell as! CommentCell
            if showTimeStamps {
                c.timeLabel.isHidden = false
            } else {
                c.timeLabel.isHidden = true
            }
            
        }
    }
    
    
}
