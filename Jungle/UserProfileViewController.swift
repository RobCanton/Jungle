//
//  UserProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import View2ViewTransition
import Firebase

extension UIViewController {
    func addNavigationBarBackdrop() {
        if let navbar = navigationController?.navigationBar {
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            blurView.frame = CGRect(x: 0, y: 0, width: navbar.frame.width, height: navbar.frame.height + 20.0)
            self.view.insertSubview(blurView, belowSubview: navbar)
        }
    }
}

class UserProfileViewController: UIViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, EditProfileProtocol {
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var navHeight: CGFloat!
    
    var postsRef:FIRDatabaseReference?
    var posts = [StoryItem]()
    var postKeys = [String]()
    
    var collectionView:UICollectionView!
    var user:User?
    
    var uid:String!
    var statusBarShouldHide = false
    
    var presentingEmptyConversation = false
    var presentConversation:Conversation?
    var partnerImage:UIImage?
    
    var status:FollowingStatus = .None
    
    override var prefersStatusBarHidden: Bool
        {
        get{
            return statusBarShouldHide
        }
    }
    
    var followers:[String]?
        {
        didSet {
            getHeaderView()?.setFollowersCount(followers!.count)
        }
    }
    var following:[String]?
        {
        didSet {
            getHeaderView()?.setFollowingCount(following!.count)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navHeight = self.navigationController!.navigationBar.frame.height + 20.0
        itemSideLength = (UIScreen.main.bounds.width - 4.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        self.addNavigationBarBackdrop()
        
        self.view.backgroundColor = UIColor.white
        self.title = "Profile"
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: navHeight,width: view.frame.width,height: view.frame.height - navHeight), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "ProfileHeaderView", bundle: nil)
        
        self.collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionView.contentInset = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        self.view.addSubview(collectionView)
        collectionView.reloadData()
        
        
        self.status = checkFollowingStatus(uid: uid)
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.user = user
                //self.title = self.user!.getUsername()
                self.collectionView.reloadData()
            }
        })

        
        if uid != mainStore.state.userState.uid {
            let moreButton = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: nil)
            moreButton.tintColor = UIColor.black
            self.navigationItem.rightBarButtonItem = moreButton
            
            UserService.listenToFollowers(uid: uid, completion: { followers in
                self.followers = followers
            })
            
            UserService.listenToFollowing(uid: uid, completion: { following in
                self.following = following
            })
        }
    
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        setFollowing()
        if navigationController?.delegate === transitionController {
            statusBarShouldHide = false
            self.setNeedsStatusBarAppearanceUpdate()
        } else {
            listenToPosts()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        statusBarShouldHide = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        if navigationController?.delegate === transitionController {
            self.navigationController?.delegate = nil
            listenToPosts()
        }
        
        setFollowing()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mainStore.unsubscribe(self)
        stopListeningToPosts()
        
        UserService.stopListeningToFollowers(uid: uid)
        UserService.stopListeningToFollowing(uid: uid)
    }
    
    func newState(state: AppState) {
        self.status = checkFollowingStatus(uid: uid)
        getHeaderView()?.setUserStatus(status: status)
        setFollowing()
    }
    
    func setFollowing() {
        if uid != mainStore.state.userState.uid { return }
        let followers = mainStore.state.socialState.followers
        var tempFollowers = [String]()
        for follower in followers {
            tempFollowers.append(follower)
        }
        
        self.followers = tempFollowers
        
        let following = mainStore.state.socialState.following
        var tempFollowing = [String]()
        for follower in following {
            tempFollowing.append(follower)
        }
        self.following = tempFollowing
    }
    
    func listenToPosts() {
        
        guard let userId = uid else { return }
       // if mainStore.state.socialState.blockedBy.contains(userId) { return }
        postsRef = UserService.ref.child("users/uploads/\(userId)")
        postsRef?.observeSingleEvent(of: .value, with: { snapshot in
            var postKeys = [String]()
            if snapshot.exists() {
                let keys = snapshot.value as! [String:AnyObject]
                for (key, _) in keys {
                    postKeys.append(key)
                }
            }
            self.postKeys = postKeys
            self.getHeaderView()?.setPostsCount(postKeys.count)
            self.downloadStory(postKeys: postKeys)
        })
    }
    
    func stopListeningToPosts() {
        postsRef?.removeAllObservers()
    }
    
    func downloadStory(postKeys:[String]) {
        if postKeys.count > 0 {
            UploadService.downloadStory(postKeys: postKeys, completion: { story in
                
                self.posts = story.sorted(by: { return $0 > $1 })
                
                self.collectionView!.reloadData()
            })
        } else {
            self.posts = [StoryItem]()
            self.collectionView.reloadData()
        }
    }
    
    func getFullUser() {
        self.user = mainStore.state.userState.user
        self.collectionView.reloadData()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! ProfileHeaderView
            view.setupHeader(_user:self.user, status: status, delegate: self)
            return view
        }
        
        return UICollectionReusableView()
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let staticHeight:CGFloat = 12 + 72 + 12 + 21 + 8 + 38 + 2 + 64
        
        if user != nil {
            let bio = user!.getBio()
            if bio != "" {
                var size =  UILabel.size(withText: bio, forWidth: collectionView.frame.size.width - 24.0, withFont: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightRegular))
                let height2 = size.height + staticHeight + 8  // +8 for some bio padding
                size.height = height2
                return size
            }
            
        }
        let size =  CGSize(width: collectionView.frame.size.width, height: staticHeight) // +8 for some empty padding
        return size
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        let post = posts[indexPath.item]
        cell.nameLabel.isHidden = true
        cell.timeLabel.isHidden = true
        cell.imageView.loadImageAsync(post.getDownloadUrl().absoluteString, completion: nil)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        print("AYE")
        self.selectedIndexPath = indexPath
        
        let galleryViewController: GalleryViewController = GalleryViewController()
        galleryViewController.uid = uid
        galleryViewController.posts = self.posts
        galleryViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": indexPath as AnyObject, "initialIndexPath": indexPath as AnyObject]
        
        if let nav = navigationController {
            //statusBarShouldHide = true
            nav.delegate = transitionController
            transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    var itemSideLength:CGFloat!
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    
    func getHeaderView() -> ProfileHeaderView? {
        if let header = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? ProfileHeaderView {
            return header
        }
        return nil
    }
}

extension UserProfileViewController: ProfileHeaderProtocol {
    
    func showFollowers() {
        guard let followers = followers else { return }
        let controller = UsersListViewController()
        controller.title = "Followers"
        controller.tempIds = followers
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showFollowing() {
        guard let following = following else { return }
        let controller = UsersListViewController()
        controller.title = "Following"
        controller.tempIds = following
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showConversation() {
        let current_uid = mainStore.state.userState.uid
        guard let partner_uid = uid else { return }
        if current_uid == partner_uid { return }
        if let conversation = checkForExistingConversation(partner_uid: current_uid) {
            prepareConversationForPresentation(conversation: conversation)
        } else {
            
            let pairKey = createUserIdPairKey(uid1: current_uid, uid2: partner_uid)
            let ref = UserService.ref.child("conversations/\(pairKey)")
            ref.child(uid).setValue(["seen": [".sv":"timestamp"]], withCompletionBlock: { error, ref in
                
                let recipientUserRef = UserService.ref.child("users/conversations/\(partner_uid)")
                recipientUserRef.child(current_uid).setValue(true)
                
                let currentUserRef = UserService.ref.child("users/conversations/\(current_uid)")
                currentUserRef.child(partner_uid).setValue(true, withCompletionBlock: { error, ref in
                    let conversation = Conversation(key: pairKey, partner_uid: partner_uid, listening: true)
                    self.presentingEmptyConversation = true
                    self.prepareConversationForPresentation(conversation: conversation)
                })
            })
        }
    }
    
    func prepareConversationForPresentation(conversation:Conversation) {
        conversation.listen()
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.presentConversation(conversation: conversation, user: user!)
            }
        })
    }
    
    func presentConversation(conversation:Conversation, user:User) {
        loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromCache in
            let controller = ChatViewController()
            controller.conversation = conversation
            controller.partnerImage = image
            controller.popUpMode = true
            let nav = UINavigationController(rootViewController: controller)
            nav.navigationBar.isTranslucent = false
            nav.navigationBar.tintColor = UIColor.black
            self.present(nav, animated: true, completion: nil)
        })
    }
    
    func showEditProfile() {
        let current_uid = mainStore.state.userState.uid
        if uid == current_uid {
            let controller = UIStoryboard(name: "EditProfileViewController", bundle: nil)
                .instantiateViewController(withIdentifier: "EditProfileNavigationController") as! UINavigationController
            let c = controller.viewControllers[0] as! EditProfileViewController
            c.delegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func changeFollowStatus() {
        switch status {
        case .CurrentUser:
            break
        case .Following:
            unfollow()
            break
        case .None:
            getHeaderView()?.setUserStatus(status: .Requested)
            UserService.followUser(uid: uid)
            break
        case .Requested:
            break
        }
    }
    
    func unfollow() {
        guard let user = self.user else { return }
        let actionSheet = UIAlertController(title: nil, message: "Unfollow \(user.getUsername())?", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Unfollow", style: .destructive)
        { action -> Void in
            
            UserService.unfollowUser(uid: user.getUserId())
        }
        actionSheet.addAction(saveActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
}

extension UserProfileViewController: View2ViewTransitionPresenting {
    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath, let attributes: UICollectionViewLayoutAttributes = self.collectionView!.layoutAttributesForItem(at: indexPath) else {
            return CGRect.zero
        }
        let navHeight = navigationController!.navigationBar.frame.height
        var y = attributes.frame.origin.y //+ navHeight
        if !isPresenting {
            //y += 20.0
        }
        
        let rect = CGRect(x: attributes.frame.origin.x, y: y, width: attributes.frame.width, height: attributes.frame.height)
        return self.collectionView!.convert(rect, to: self.collectionView!.superview)
    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        let cell: UICollectionViewCell = self.collectionView!.cellForItem(at: indexPath)!
        
        return cell.contentView
    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        
        if !isPresenting {
            self.collectionView!.reloadData()
            self.collectionView!.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            self.collectionView!.layoutIfNeeded()
        }
    }
    
    func dismissInteractionEnded(_ completed: Bool) {
        if completed {
        }
    }
}



