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

enum MyPostsMode {
    case publicPosts, anonymousPosts
}

class MyProfileViewController: RoundedViewController, StoreSubscriber, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, EditProfileProtocol {
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var posts = [StoryItem]()
    var postKeys = [String]()
    var anonPosts = [StoryItem]()
    var anonPostKeys = [String]()
    var collectionView:UICollectionView!
    var user:User?
    
    var uid:String!
    var statusBarShouldHide = false
    var status:FollowingStatus = .None
    var tabHeader:ProfileTabHeader!
    
    var mode = MyPostsMode.publicPosts
    
    override var prefersStatusBarHidden: Bool
        {
        get{
            return statusBarShouldHide
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uid = mainStore.state.userState.uid
        view.backgroundColor = UIColor.clear
        itemSideLength = (UIScreen.main.bounds.width - 2.0)/3.0
        self.automaticallyAdjustsScrollViewInsets = false
        
        mode = userState.anonMode ? .anonymousPosts : .publicPosts
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        tabHeader = UINib(nibName: "ProfileTabHeader", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ProfileTabHeader
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
        
        let headerNib = UINib(nibName: "MyProfileHeaderView", bundle: nil)
        
        self.collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
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
                self.collectionView.reloadData()
            }
        })

        getHeaderView()?.setFollowersCount(mainStore.state.socialState.followers.count)
        getHeaderView()?.setFollowingCount(mainStore.state.socialState.following.count)
        
        
        listenToPosts()
        getAnonPosts()
    }
    
    
    func controlDidChange(_ _mode:MyPostsMode) {
        if self.mode == _mode { return }
        self.mode = _mode
        switch mode {
        case .publicPosts:
            //mainStore.dispatch(GoPublic())
            self.mode = .publicPosts
            break
        case .anonymousPosts:
            //mainStore.dispatch(GoAnonymous())
            self.mode = .anonymousPosts
            break
        }
        self.collectionView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        mainStore.subscribe(self)
        
        tabHeader.settingsButton.tintColor = UserService.isEmailVerified ? UIColor(white: 0.42, alpha: 1.0) : errorColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenToPosts()
        getAnonPosts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        mainStore.unsubscribe(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListeningToPosts()
    }
    
    func newState(state: AppState) {
        getHeaderView()?.setUserStatus(status: .CurrentUser)
        getHeaderView()?.setFollowersCount(state.socialState.followers.count)
        getHeaderView()?.setFollowingCount(state.socialState.following.count)
    }
    
    
    var postsRef:DatabaseReference?
    
    func listenToPosts() {
        
        guard let userId = uid else { return }
        stopListeningToPosts()
        // if mainStore.state.socialState.blockedBy.contains(userId) { return }
        postsRef = UserService.ref.child("users/uploads/public/\(userId)")
        postsRef?.observeSingleEvent(of: .value, with: { snapshot in
            var postKeys = [String]()
            if snapshot.exists() {
                let keys = snapshot.value as! [String:AnyObject]
                for (key, _) in keys {
                    postKeys.append(key)
                }
            }
            
            self.downloadStory(postKeys: postKeys)
        })
    }
    
    
    
    func downloadStory(postKeys:[String]) {
        if postKeys.count > 0 {
            UploadService.downloadStory(postKeys: postKeys, completion: { story in
                
                self.posts = story.sorted(by: { return $0 > $1 })
                self.getHeaderView()?.setPostsCount(self.posts.count)
                self.collectionView!.reloadData()
            })
        } else {
            self.posts = [StoryItem]()
            self.collectionView.reloadData()
        }
    }
    
    func getAnonPosts() {
        guard let userId = uid else { return }
        let anonPostsRef = UserService.ref.child("users/uploads/anon/\(userId)")
        anonPostsRef.observeSingleEvent(of: .value, with: { snapshot in
            var anonPostKeys = [String]()
            if snapshot.exists() {
                let keys = snapshot.value as! [String:AnyObject]
                for (key, _) in keys {
                    anonPostKeys.append(key)
                }
            }
            
            self.downloadAnonPosts(postKeys: anonPostKeys)
        })
    }
    
    func downloadAnonPosts(postKeys:[String]) {
        if postKeys.count > 0 {
            UploadService.downloadStory(postKeys: postKeys, completion: { story in
                
                self.anonPosts = story.sorted(by: { return $0 > $1 })
                self.collectionView!.reloadData()
            })
        } else {
            self.anonPosts = [StoryItem]()
            self.collectionView.reloadData()
        }
    }
    
    func stopListeningToPosts() {
        postsRef?.removeAllObservers()
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
        }
    }
    
    
    func getFullUser() {
        self.user = mainStore.state.userState.user
        self.collectionView.reloadData()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath as IndexPath) as! MyProfileHeaderView
            view.setupHeader(_user:self.user, status: .CurrentUser, delegate: self)
            view.setupControl(mode)
            view.controlHandler = controlDidChange
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let staticHeight:CGFloat = 12 + 72 + 12 + 21 + 8 + 38 + 2 + 64 + 44 + 2
        
        if user != nil {
            let bio = user!.bio
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
        switch mode {
        case .publicPosts:
            return posts.count
        case .anonymousPosts:
            return anonPosts.count
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath as IndexPath) as! PhotoCell
        
        switch mode {
        case .publicPosts:
            cell.setupCell(withPost: posts[indexPath.item])
        case .anonymousPosts:
            cell.setupCell(withPost: anonPosts[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCell
        
        self.selectedIndexPath = indexPath

        switch mode {
        case .publicPosts:
            globalMainInterfaceProtocol?.presentProfileStory(posts: posts, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            break
        case .anonymousPosts:
            globalMainInterfaceProtocol?.presentProfileStory(posts: anonPosts, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            break
        }
        
        
        collectionView.deselectItem(at: indexPath, animated: true)
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
    
    
    func getHeaderView() -> MyProfileHeaderView? {
        if let header = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? MyProfileHeaderView {
            return header
        }
        return nil
    }

    
}

extension MyProfileViewController: ProfileHeaderProtocol {
    
    func showFollowers() {
        guard let _user = user else { return }
        guard let _uid = uid else { return }
        if _user.followers == 0 { return }
        let controller = UsersListViewController()
        controller.type = .Followers
        controller.uid = _uid
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func showFollowing() {
        guard let _user = user else { return }
        guard let _uid = uid else { return }
        if _user.following == 0 { return }
        let controller = UsersListViewController()
        controller.type = .Following
        controller.uid = _uid
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func showConversation() {}
    
    
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
    
    func changeFollowStatus() {}
}





