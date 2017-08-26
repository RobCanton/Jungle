//
//  PostMetaView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-25.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

protocol PostMetaProtocol:class {
    func dismissMetaView()
}

enum PostMetaMode {
    case likes, comments, topComments
}

class PostMetaView:UIView, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource  {
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var likesButton: UIButton!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var notificationsButton: UIButton!
    @IBOutlet weak var controlContainer: UIView!
    @IBOutlet weak var mainView: UIView!
    
    var likers = [Any]()
    var slider:UIView!
    weak var delegate:PostMetaProtocol?
    var pageScrollView:UIScrollView!
    
    var likesTableView:UITableView!
    var commentsTableView:UITableView!
    var topTableView:UITableView!
    
    var mode:PostMetaMode = .comments
    
    weak var item:StoryItem?
    weak var state:ItemStateController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let sliderHeight:CGFloat = 2.0
        slider?.removeFromSuperview()
        slider = UIView(frame: CGRect(x: 0, y: controlContainer.frame.height - sliderHeight, width: likesButton.frame.width, height: sliderHeight))
        slider.backgroundColor = UIColor.darkGray
        controlContainer.insertSubview(slider, at: 0)
        
        pageScrollView = UIScrollView(frame: mainView.bounds)
        pageScrollView.showsHorizontalScrollIndicator = false
        pageScrollView.bounces = true
        pageScrollView.delegate = self
        pageScrollView.isPagingEnabled = true
        
        pageScrollView.contentSize = CGSize(width: pageScrollView.bounds.width * 3.0, height: pageScrollView.bounds.height)
        mainView.addSubview(pageScrollView)
        
        likesTableView = UITableView(frame: CGRect(x: 0, y: 0, width: pageScrollView.bounds.width, height: pageScrollView.bounds.height))
        
        let userViewCell = UINib(nibName: "UserViewCell", bundle: nil)
        likesTableView.register(userViewCell, forCellReuseIdentifier: "userCell")
        
        likesTableView.backgroundColor = UIColor.clear
        likesTableView.bounces = false
        likesTableView.delegate = self
        likesTableView.dataSource = self
        likesTableView.tableHeaderView = UIView()
        likesTableView.tableFooterView = UIView()
        pageScrollView.addSubview(likesTableView)
        
        commentsTableView = UITableView(frame: CGRect(x: pageScrollView.bounds.width, y: 0, width: pageScrollView.bounds.width, height: pageScrollView.bounds.height))
        let commentViewCell = UINib(nibName: "CommentViewCell", bundle: nil)
        commentsTableView.register(commentViewCell, forCellReuseIdentifier: "commentCell")
        commentsTableView.backgroundColor = UIColor.blue
        commentsTableView.bounces = false
        commentsTableView.tableHeaderView = UIView()
        commentsTableView.tableFooterView = UIView()
        pageScrollView.addSubview(commentsTableView)
        
        topTableView = UITableView(frame: CGRect(x: pageScrollView.bounds.width * 2.0, y: 0, width: pageScrollView.bounds.width, height: pageScrollView.bounds.height))
        topTableView.register(commentViewCell, forCellReuseIdentifier: "commentCell")
        topTableView.backgroundColor = UIColor.green
        topTableView.bounces = false
        topTableView.tableHeaderView = UIView()
        topTableView.tableFooterView = UIView()
        pageScrollView.addSubview(topTableView)
        
        
    }
    
    func setup(withItem item:StoryItem, state:ItemStateController) {
        self.item = item
        self.state = state
        
        fetchLikes(item)
    }
    
    
    func fetchLikes(_ item:StoryItem) {
        UserService.getHTTPSHeaders() { HTTPHeaders in
            guard let headers = HTTPHeaders else { return }
            print("\(API_ENDPOINT)/likes/\(item.key)")
            Alamofire.request("\(API_ENDPOINT)/likes/\(item.key)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                DispatchQueue.main.async {
                    if let json = response.result.value as? [String:Any],
                        let success = json["success"] as? Bool,
                        let likes = json["likes"] as? [Any]  {
                        
                        var _likers = [Any]()
                        
                        for liker in likes {
                            if let uid = liker as? String {
                                _likers.append(uid)
                            } else if let anon = liker as? [String:Any],
                                let aid = anon["aid"] as? String,
                                let adjective = anon["adjective"] as? String,
                                let animal = anon["animal"] as? String,
                                let color = anon["color"] as? String {
                                let anonObject = AnonObject(adjective: adjective, animal: animal, colorHexcode: color)
                                anonObject.aid = aid
                                _likers.append(anonObject)
                            }
                        }
                        self.likers = _likers
                        self.likesTableView.reloadData()
                        
                        print("LIKES RESPONSE: \(likes)")
                        return
                        
                    } else {
                        print("ERROR!: \(response.error)")
                        return
                    }
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case likesTableView:
            return likers.count
        case commentsTableView:
            return 0
        case topTableView:
            return 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case likesTableView:
            return 60
        case commentsTableView:
            return 0
        case topTableView:
            return 0
        default:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case likesTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserViewCell
            if let uid = likers[indexPath.row] as? String {
                cell.setupUser(uid: uid)
                cell.selectionStyle = .default
                //cell.delegate = self
            } else if let anon = likers[indexPath.row] as? AnonObject {
                cell.setupAnon(anon)
                cell.selectionStyle = .default
                cell.delegate = nil
            }
            cell.backgroundColor = nil
            cell.contentView.backgroundColor = nil
            //cell.delegate = self
            let labelX = cell.usernameLabel.frame.origin.x
            cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
            return cell
        case commentsTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! DetailedCommentCell
            return cell
        case topTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! DetailedCommentCell
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! DetailedCommentCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let commentCell = cell as? DetailedCommentCell {
            commentCell.reset()
        }
    }
    
    
    @IBAction func dismissTapped(_ sender: Any) {
        delegate?.dismissMetaView()
    }
    @IBAction func likesTapped(_ sender: Any) {
        pageScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    @IBAction func commentsTapped(_ sender: Any) {
        pageScrollView.setContentOffset(CGPoint(x: pageScrollView.frame.width, y: 0), animated: true)
    }
    @IBAction func topTapped(_ sender: Any) {
        pageScrollView.setContentOffset(CGPoint(x: pageScrollView.frame.width * 2.0, y: 0), animated: true)
    }
    
    @IBAction func notificationsTapped(_ sender: Any) {
        
    }
    
    func setMode(_ _mode:PostMetaMode) {
        self.mode = _mode
        switch _mode {
        case .likes:
            likesButton.isEnabled = false
            commentsButton.isEnabled = true
            topButton.isEnabled = true
            break
        case .comments:
            likesButton.isEnabled = true
            commentsButton.isEnabled = false
            topButton.isEnabled = true
            break
        case .topComments:
            likesButton.isEnabled = true
            commentsButton.isEnabled = true
            topButton.isEnabled = false
            break
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView !== pageScrollView { return }
        let xOffset = scrollView.contentOffset.x
        let sWidth = scrollView.frame.width
        if xOffset < sWidth {
            setMode(.likes)
        } else if xOffset >= sWidth && xOffset < sWidth * 2.0 {
            setMode(.comments)
        } else {
            setMode(.topComments)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView !== pageScrollView { return }
        let sWidth = scrollView.frame.width
        let xOffset = scrollView.contentOffset.x
        print("xOffset: \(xOffset)")
        if xOffset < sWidth {
            let progress = xOffset / sWidth
            let sliderFrame = slider.frame
            let x = likesButton.frame.width * progress
            let width = likesButton.frame.width + 20.0 * progress
            slider.frame = CGRect(x: x, y: sliderFrame.origin.y, width: width, height: sliderFrame.height)
            
        } else if xOffset >= sWidth {
            let progress = ((xOffset - sWidth) / sWidth)
            let sliderFrame = slider.frame
            let x = likesButton.frame.width + commentsButton.frame.width * progress
            let width = commentsButton.frame.width - 30.0 * progress
            slider.frame = CGRect(x: x, y: sliderFrame.origin.y, width: width, height: sliderFrame.height)
        }
        
    }
}
