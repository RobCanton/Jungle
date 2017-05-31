//
//  PostFooterView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-04-25.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

protocol PostFooterProtocol: class {
    func liked(_ liked:Bool)
}

class PostFooterView: UIView {
    
    @IBOutlet weak var block: UIView!
    
    @IBOutlet weak var commentsLabel: UILabel!
    
    var gradient:CAGradientLayer?
    @IBOutlet weak var gradientView: UIView!
    
    weak var delegate:PostFooterProtocol?
    var pullUpTapHandler:(()->())?
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(blockTapped))
        block.isUserInteractionEnabled = true
        block.addGestureRecognizer(tap)
        
        
    }

    func blockTapped() {
        pullUpTapHandler?()
    }
    
    func setCommentsLabelToCount(_ count:Int) {
        
        if count == 0 {
            commentsLabel.text = "COMMENT"
        } else if count == 1 {
            commentsLabel.text = "\(count) COMMENT"
        } else {
            commentsLabel.text = "\(getNumericShorthandString(count)) COMMENTS"
        }
        
        self.applyShadow(radius: 3.0, opacity: 0.5, height: 0.0, shouldRasterize: false)
    
    }
    
    func setup(_ item:StoryItem) {

        setCommentsLabelToCount(item.getNumComments())
        let numCommentsRef = UserService.ref.child("uploads/meta/\(item.getKey())/comments")
        numCommentsRef.removeAllObservers()
        numCommentsRef.observe(.value, with: { snapshot in
            var numComments = 0
            if snapshot.exists() {
                if let _numComments = snapshot.value as? Int {
                    numComments = _numComments
                }
            }
            
            item.updateNumComments(numComments)
            self.setCommentsLabelToCount(item.getNumComments())
        })

        //setupLiked(item.likes[mainStore.state.userState.uid] != nil)

    }
    @IBOutlet weak var likeButton: UIButton!
    @IBAction func likeTapped(_ sender: Any) {
        //setupLiked(!self.liked, animated: true)
        delegate?.liked(!liked)
    }
    var liked = false
    func setupLiked(_ liked:Bool, animated: Bool) {
        self.liked = liked
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
            likeButton.setImage(UIImage(named:"like"), for: .normal)
        }
    }
    
    
    func clean() {
        commentsLabel.text = "COMMENT"
    }
}
