//
//  CommentBar.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-09.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

protocol CommentItemBarProtocol {
    func sendComment(_ comment:String)
    func toggleLike(_ like:Bool)
    func editCaption()
    func showMore()
}

class CommentItemBar: UIView {
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var delegate:CommentItemBarProtocol?
    var liked = false
    var editCaptionMode = false
    var isKeyboardUp = false
    
    weak var itemRef:StoryItem?
    
    var userImageTap:UITapGestureRecognizer!
    
    var placeHolderString:String!
    override func awakeFromNib() {
        sendButton.alpha = 0.0
        placeHolderString = "Comment"
        textField.autocapitalizationType = .sentences
        textField.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
        textField.placeholder = placeHolderString
        sendButton.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: false)
        userImageView.cropToCircle()
        
        userImageTap = UITapGestureRecognizer(target: self, action: #selector(switchAnonMode))
        userImageView.addGestureRecognizer(userImageTap)
        userImageView.isUserInteractionEnabled = true
    }
    
    
    @IBAction func likeTapped(_ sender: Any) {
        if currentUserMode {
            ///delegate?.editCaption()
            editCaptionMode = true
            textField.becomeFirstResponder()
            return
        }
        setLikedStatus(!self.liked, animated: true)
        delegate?.toggleLike(liked)
    }
    
    var currentUserMode = false
    
    
    func setup(_ item:StoryItem) {
        self.itemRef = item
        
        self.currentUserMode = isCurrentUserId(id: item.authorId)
        if currentUserMode {
            self.likeButton.setImage(UIImage(named: "edit"), for: .normal)
            self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(4.0, 4.0, 4.0, 4.0)
        } else {
            self.likeButton.setImage(UIImage(named: "like"), for: .normal)
            self.likeButton.imageEdgeInsets = UIEdgeInsets.zero
        }
        showCurrentAnonMode()
    }
    
    func switchAnonMode() {
        mainStore.dispatch(ToggleAnonMode())
        showCurrentAnonMode()
    }
    
    func showCurrentAnonMode() {
        let isAnon = mainStore.state.userState.anonMode
        if isAnon {
            placeHolderString = "Comment anonymously"
            userImageView.image = isDarkMode ? UIImage(named: "private_dark") : UIImage(named:"private2")
        } else {
            guard let user = mainStore.state.userState.user else {
                userImageView.image = nil
                return
            }
            placeHolderString = "Comment as @\(user.username)"
            userImageView.loadImageAsync(user.imageURL, completion: nil)
        }
        
        if isKeyboardUp {
            if isDarkMode {
                textField.attributedPlaceholder =
                    NSAttributedString(string: placeHolderString, attributes: [NSForegroundColorAttributeName : UIColor.gray])
            } else  {
                textField.placeholder = placeHolderString
            }
        }
    }
    
    var isDarkMode = false
    
    func darkMode() {
        isDarkMode = true
        activityIndicator.tintColor = UIColor.gray
        sendButton.tintColor = UIColor.black
        sendButton.setTitleColor(UIColor.black, for: .normal)
        sendButton.alpha = 0.5
        textField.keyboardAppearance = .light
        textField.textColor = UIColor.black
        textField.applyShadow(radius: 0, opacity: 0, height: 0, shouldRasterize: false)
        textField.attributedPlaceholder =
            NSAttributedString(string: "Comment", attributes: [NSForegroundColorAttributeName : UIColor.gray])
        sendButton.applyShadow(radius: 0, opacity: 0, height: 0, shouldRasterize: false)
        
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 1))
        bar.backgroundColor = UIColor(white: 0.90, alpha: 1.0)
        addSubview(bar)
        likeButton.isHidden = true
        likeButton.isEnabled = false
        moreButton.isHidden = true
        moreButton.isEnabled = false

        
        backgroundView.alpha = 1.0
        backgroundView.backgroundColor =  UIColor.clear
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = backgroundView.bounds
        backgroundView.addSubview(blur)
        
        
        
    }
    
    
    func setLikedStatus(_ _liked:Bool, animated: Bool) {
        if currentUserMode { return }
        self.liked = _liked
        
        if self.liked  {
            likeButton.setImage(UIImage(named: "liked"), for: .normal)
            if animated {
                likeButton.setImage(UIImage(named: "liked"), for: .normal)
                self.likeButton.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                
                UIView.animate(withDuration: 0.5, delay: 0.0,
                               usingSpringWithDamping: 0.5,
                               initialSpringVelocity: 1.6,
                               options: .curveEaseOut,
                               animations: {
                                self.likeButton.transform = CGAffineTransform.identity
                },
                               completion: nil)
            }
            
        } else {
            likeButton?.setImage(UIImage(named:"like"), for: .normal)
        }
    }
    
    
    @IBAction func moreTapped(_ sender: Any) {
        delegate?.showMore()
    }
    
    @IBAction func sendButton(_ sender: Any) {
        if let text = textField.text {
            textField.text = ""
            delegate?.sendComment(text)
        }
        
    }
    
    func setBusyState(_ busy: Bool) {
        if busy {
            sendButton.isEnabled = false
            sendButton.isHidden = true
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            sendButton.isEnabled = true
            sendButton.isHidden = false
        }
    }

    func setKeyboardUp(_ up:Bool) {
        self.isKeyboardUp = up
        if up {
            likeButton?.isUserInteractionEnabled = false
            moreButton?.isUserInteractionEnabled = false
            sendButton?.isUserInteractionEnabled = true
            
            if editCaptionMode {
                textField.placeholder = "Edit Caption"
                sendButton.setImage(nil, for: .normal)
                sendButton.setTitle("Set", for: .normal)
                moreButton.isHidden = true
                likeButton.isHidden = true
                textField.text = itemRef != nil ? itemRef!.caption : nil
                
                if let item = itemRef {
                    if item.anon != nil {
                        userImageView.image = isDarkMode ? UIImage(named: "private_dark") : UIImage(named:"private2")
                    } else if let user = userState.user {
                        userImageView.loadImageAsync(user.imageURL, completion: nil)
                    }
                }
            } else if isDarkMode {
                textField.attributedPlaceholder =
                    NSAttributedString(string: placeHolderString, attributes: [NSForegroundColorAttributeName : UIColor.gray])
            } else  {
                textField.placeholder = placeHolderString
                
            }
            
        } else {
            
            
            likeButton?.isUserInteractionEnabled = true
            moreButton?.isUserInteractionEnabled = true
            sendButton?.isUserInteractionEnabled = false
            
            if editCaptionMode {
                editCaptionMode = false
                textField.text = nil
                sendButton.setTitle("", for: .normal)
                sendButton.setImage(UIImage(named: "send"), for: .normal)
                moreButton.isHidden = false
                likeButton.isHidden = false
                
                if userState.anonMode {
                    userImageView.image = isDarkMode ? UIImage(named: "private_dark") : UIImage(named:"private2")
                } else if let user = userState.user {
                    userImageView.loadImageAsync(user.imageURL, completion: nil)
                }
                
            }
            
            if isDarkMode {
                textField.attributedPlaceholder =
                    NSAttributedString(string: "Comment", attributes: [NSForegroundColorAttributeName : UIColor.gray])
            } else {
                textField.placeholder = "Comment"
            }
        }
    }
    
    func reset() {
        textField.text = nil
        itemRef = nil
        liked = false
        editCaptionMode = false
        isKeyboardUp = false
    }
    
}
