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
}

class CommentsOverlayTableView: UIView, UITableViewDelegate, UITableViewDataSource, CommentCellProtocol {
    
    var comments = [Comment]()
    
    var tableView:UITableView!
    var divider:UIView!
    var hasCaption = false
    
    weak var delegate:CommentsTableProtocol?
    
    func cleanUp() {
        comments = [Comment]()
        tableView.reloadData()
        divider.isHidden = true
        delegate = nil
    }
    
    func showAuthor(_ uid: String) {
        delegate?.showUser(uid)
    }
    
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
        tableView.tableHeaderView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()

        self.addSubview(tableView)
        
        divider = UIView(frame: CGRect(x: 8,y: frame.height-1, width: frame.width-16, height: 1))
        divider.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        self.addSubview(divider)
        
        reloadTable()
        scrollBottom(animated: false)
    }
    
    func setTableComments(comments:[Comment], animated:Bool)
    {
        self.comments = comments
        divider.isHidden = hasCaption || comments.count == 0
        reloadTable()
        scrollBottom(animated: animated)
    }
    
    
    func reloadTable() {
        
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
        let width = tableView.frame.width - (10 + 8 + 10 + 32)
        let size =  UILabel.size(withText: text, forWidth: width, withFont: UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightRegular))
        let height2 = size.height + 26 + 4  // +8 for some bio padding
        return height2
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
        cell.setContent(comment: comments[indexPath.row])
        cell.authorLabel.textColor = UIColor.white
        cell.commentLabel.textColor = UIColor.white
        cell.timeLabel.textColor = UIColor.white
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
        if let username = cell.authorLabel.text  {
            let text = comments[indexPath.row].text
            let sheet = UIAlertController(title: username, message: text, preferredStyle: .actionSheet)
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.addAction(UIAlertAction(title: "Reply", style: .default, handler: nil))
            sheet.addAction(UIAlertAction(title: "Report", style: .destructive, handler: nil))
            globalMainInterfaceProtocol?.presentPopover(withController: sheet, animated: true)
        }
        
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