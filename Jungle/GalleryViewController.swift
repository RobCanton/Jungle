//
//  StoriesViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import View2ViewTransition

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    weak var transitionController: TransitionController!

    var posts = [StoryItem]()
    
    var collectionContainerView:UIView!
    var collectionView:UICollectionView!
    
    var isSingleItem = false
    var showCommentsOnAppear = false
    
    var statusBarShouldHide = false
    var shouldScrollToBottom = false
    
    var currentIndexPath:IndexPath?
    
    deinit {
        print("Deinit >> GalleryViewController")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if self.navigationController!.delegate !== transitionController {
            self.collectionView.reloadData()
        }
        globalMainInterfaceProtocol?.statusBar(hide: true, animated: false)
        
        if showCommentsOnAppear {
            showCommentsOnAppear = false
            getCurrentCell()?.setDetailFade(0.0)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(foreground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            self.getCurrentCell()?.replayVideo()
        }
    }
    
    func foreground() {
        getCurrentCell()?.setOverlays()
    }
    
    
    func keyboardStateChange(_ up: Bool) {
        collectionView.isScrollEnabled = !up
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
        
        self.navigationController?.delegate = transitionController
        
        getCurrentCell()?.resume()
        
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                    
                }
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        for cell in collectionView.visibleCells as! [PostViewController] {
            cell.pause()
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        for cell in collectionView.visibleCells as! [PostViewController] {
            cell.cleanUp()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.black
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = UIScreen.main.bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        collectionContainerView = UIView(frame: UIScreen.main.bounds)
        collectionView = UICollectionView(frame: collectionContainerView.bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        collectionView.register(PostViewController.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.black
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.isOpaque = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        collectionContainerView.addSubview(collectionView)
        collectionContainerView.applyShadow(radius: 5.0, opacity: 0.25, height: 0.0, shouldRasterize: false)
        
        self.view.addSubview(collectionContainerView)
  
    }
    
    func appMovedToBackground() {
        dismissPopup(false)
    }
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let cell = getCurrentCell() else { return false }
        let keyboardUp = cell.keyboardUp
        
        let point = gestureRecognizer.location(ofTouch: 0, in: self.view)
        let authorBottomY = cell.headerView.frame.origin.y + cell.headerView.frame.height
        let commentsTableHeight = cell.commentsView.getTableHeight()
        let commentsTopY = cell.infoView.frame.origin.y - commentsTableHeight
        
        
            if point.y > commentsTopY || point.y < authorBottomY {
                return false
            }
        
        let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
        if !isSingleItem {
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
        }
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
        
        if keyboardUp {
            if translate.y > 0 {
                cell.commentBar.textField.resignFirstResponder()
            }
            return false
        } else {
            if let item = cell.storyItem {
                if translate.y < 0 && !item.shouldBlock {
                    cell.commentBar.textField.becomeFirstResponder()
                }
            }

        }
        
        return Double(abs(translate.y)/abs(translate.x)) > Double.pi / 4 && translate.y > 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.main.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PostViewController = collectionView.dequeueReusableCell(withReuseIdentifier: "presented_cell", for: indexPath as IndexPath) as! PostViewController
        cell.delegate = self
        cell.preparePost(posts[indexPath.item], cellIndex: indexPath.item)
        return cell
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        if !isSingleItem {
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
        }
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
        
        return Double(abs(translate.y)/abs(translate.x)) > Double.pi / 4 && translate.y > 0
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        var visibleRect = CGRect()
        
        visibleRect.origin = collectionView.contentOffset
        visibleRect.size = collectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath: IndexPath = collectionView.indexPathForItem(at: visiblePoint)!
        
        currentIndexPath = visibleIndexPath
        
        if let cell = getCurrentCell() {
            cell.resume()
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! PostViewController
        cell.reset()
    }
    
    func getCurrentCell() -> PostViewController? {
        if let index = currentIndexPath {
            if let cell = collectionView.cellForItem(at: index) as? PostViewController {
                return cell
            }
        }
        return nil
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
}

extension GalleryViewController: PopupProtocol {
    
    func dismissPopup(_ animated:Bool) {
        getCurrentCell()?.pause()
        getCurrentCell()?.destroyVideoPlayer()
        if let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first {
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
            if !isSingleItem {
                self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
            }
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            
            navigationController?.popViewController(animated: animated)
        }
    }
    
    func showUser(_ uid:String) {
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = UserProfileViewController()
        controller.uid = uid
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func showPlace(_ location:Location) {
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = PlaceViewController()
        controller.place = location
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func showMetaLikes() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.storyItem else { return }
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = PostMetaTableViewController()
        controller.itemStateController = cell.itemStateController
        controller.item = item
        controller.mode = .likes
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func showMetaComments(_ indexPath:IndexPath?) {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.storyItem else { return }
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = PostMetaTableViewController()
        controller.itemStateController = cell.itemStateController
        controller.item = item
        controller.mode = .comments
        controller.initialIndex = indexPath
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func showMore() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.storyItem else {
            cell.resume()
        return }
        
        if cell.storyItem.authorId == mainStore.state.userState.uid {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                cell.resume()
            }
            actionSheet.addAction(cancelActionButton)
            
            let subscribed = cell.subscribedToPost
            var message = "Recieve Notifications"
            
            if subscribed {
                message = "Mute Notifications"
            }
            let notificationsAction = UIAlertAction(title: message, style: .default) { (action) in
                UploadService.subscribeToPost(withKey: item.key, subscribe: !subscribed)
            }
            actionSheet.addAction(notificationsAction)
            
            let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive) { action -> Void in
                UploadService.deleteItem(item: item) { success in
                    if success {
                        self.dismissPopup(true)
                    }
                }
            }
            actionSheet.addAction(deleteAction)
            self.present(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                cell.resume()
            }
            actionSheet.addAction(cancelActionButton)
            
            let subscribed = cell.subscribedToPost
            var message = "Recieve Notifications"
            
            if subscribed {
                message = "Mute Notifications"
            }
            let notificationsAction = UIAlertAction(title: message, style: .default) { (action) in
               UploadService.subscribeToPost(withKey: item.key, subscribe: !subscribed)
            }
            actionSheet.addAction(notificationsAction)
            
            let OKAction = UIAlertAction(title: "Report", style: .destructive) { (action) in
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                    cell.resume()
                }
                alertController.addAction(cancelAction)
                
                let OKAction = UIAlertAction(title: "It's Inappropriate", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Inappropriate, completion: { success in
                    })
                }
                alertController.addAction(OKAction)
                
                let OKAction2 = UIAlertAction(title: "It's Spam", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Spam, completion: { success in
                        
                    })
                }
                alertController.addAction(OKAction2)
                
                self.present(alertController, animated: true, completion: nil)
            }
            actionSheet.addAction(OKAction)
            
            self.present(actionSheet, animated: true, completion: nil)
        }
        
    }
    
}



extension GalleryViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for cell in collectionView.visibleCells as! [PostViewController] {
            cell.pause()
        }
        
        //getCurrentCell()?.pause()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
}


extension GalleryViewController: View2ViewTransitionPresented {
    
    func destinationFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }
    
    func destinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
        let cell: PostViewController = self.collectionView.cellForItem(at: indexPath) as! PostViewController
        
        cell.prepareForTransition(isPresenting: isPresenting)
        return view
    }
    
    func prepareDestinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) {
        
        if isPresenting {
            let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
            currentIndexPath = indexPath
            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOffset
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
}

