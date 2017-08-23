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
    func commentMentionTapped(_ mention:String)
    func commentAuthorTapped(_ comment:Comment)
    func commentLikeTapped(_ comment:Comment, _ liked:Bool)
    func commentReplyTapped(_ comment:Comment, _ username:String)
}

protocol CommentsHeaderProtocol: class {
    func dismissFromHeader()
    func actionHandler()
    func setInfoMode(_ mode:PostInfoMode)
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
