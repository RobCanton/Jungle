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



class MyProfileViewController: temp, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, EditProfileProtocol {
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var posts = [StoryItem]()
    var postKeys = [String]()
    var collectionView:UICollectionView!
    var user:User?
    
    var uid:String!
    var statusBarShouldHide = false
    
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
        uid = mainStore.state.userState.uid
        view.backgroundColor = UIColor.clear
        itemSideLength = (UIScreen.main.bounds.width - 4.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = false
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let tabHeader = UINib(nibName: "ProfileTabHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ProfileTabHeader
        tabHeader.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)
        
        self.view.addSubview(tabHeader)
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        collectionView = UICollectionView(frame: CGRect(x: 0,y: 44,width: view.frame.width,height: view.frame.height - 44), collectionViewLayout: layout)
        
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
        
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.user = user
                self.title = self.user!.getUsername()
                self.collectionView.reloadData()
            }
        })

        
        
        listenToPosts()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenToPosts()
        setFollowing()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        mainStore.unsubscribe(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListeningToPosts()
    }
    
    func newState(state: AppState) {
        let status = checkFollowingStatus(uid: uid)
        getHeaderView()?.setUserStatus(status: status)
        
        setFollowing()
        
    }
    
    func setFollowing() {
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
    
    
    var postsRef:FIRDatabaseReference?
    
    func listenToPosts() {
        
        guard let userId = uid else { return }
        stopListeningToPosts()
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
    
    var presentingEmptyConversation = false
    
    func handleMessageTapped() {
        
        let current_uid = mainStore.state.userState.uid
        
        if uid == current_uid {
            let controller = UIStoryboard(name: "EditProfileViewController", bundle: nil)
                .instantiateViewController(withIdentifier: "EditProfileNavigationController") as! UINavigationController
            let c = controller.viewControllers[0] as! EditProfileViewController
            c.delegate = self
            self.present(controller, animated: true, completion: nil)
        } else {
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
    }
    
    
    func getFullUser() {
        self.user = mainStore.state.userState.user
        self.collectionView.reloadData()
    }
    
    var presentConversation:Conversation?
    var partnerImage:UIImage?
    
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! ProfileHeaderView
            view.setupHeader(_user:self.user)
            view.messageHandler = handleMessageTapped
            view.unfollowHandler = unfollowHandler
            return view
        }
        
        return UICollectionReusableView()
    }
    var text:String?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let staticHeight:CGFloat = 8 + 140
        if user != nil {
            let bio = user!.getBio()
            
            //text = "Here is my bio about absolutely nothing important. but u can catch me out side mannn dem."
            if bio != "" {
                var size =  UILabel.size(withText: bio, forWidth: collectionView.frame.size.width - 24.0, withFont: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightMedium))
                let height2 = size.height + staticHeight + 12  // +8 for some bio padding
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
        
        self.selectedIndexPath = indexPath
        
        globalMainRef?.presentProfileStory(posts: posts, destinationIndexPath: indexPath, initialIndexPath: indexPath)
        
        collectionView.deselectItem(at: indexPath, animated: true)
        /*
        let galleryViewController: GalleryViewController = GalleryViewController()
        galleryViewController.uid = uid
        galleryViewController.posts = self.posts
        galleryViewController.transitionController = self.transitionController
        self.transitionController.userInfo = ["destinationIndexPath": indexPath as AnyObject, "initialIndexPath": indexPath as AnyObject]
        
        if let nav = navigationController {
            //statusBarShouldHide = true
            nav.delegate = transitionController
            transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
        }*/
        
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
    
    
    func unfollowHandler() {
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





