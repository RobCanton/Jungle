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
import AnimatedCollectionViewLayout

protocol PopupProtocol: class {
    func showMore()
    func showUser(_ uid:String)
    func showPlace(_ location:Location)
    func showRegion(_ region:City)
    func dismissPopup(_ animated:Bool)
    func keyboardStateChange(_ up:Bool)
    func showAnonOptions(_ aid:String)
    func showMetaLikes()
    func showMetaComments(_ indexPath:IndexPath?)
}

class StoriesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    weak var transitionController: TransitionController!
    
    var stories:[Story]!
    
    var collectionContainerView:UIView!
    var collectionView:UICollectionView!
    
    var longPressGR:TimedLongPressGestureRecognizer!
    var firstCell = true
    
    var currentIndexPath:IndexPath?
    {
        willSet {
            getCurrentCell()?.isCurrentItem = false
            print("Prev value: \(currentIndexPath)")
        }
        didSet {
            getCurrentCell()?.isCurrentItem = true
            print("Next value: \(currentIndexPath)")
        }
    }
    
    var startIndex:Int?
    
    deinit {
        print("Deinit >> StoriesViewController")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if self.navigationController!.delegate !== transitionController {
            self.collectionView.reloadData()
        }
        
        globalMainInterfaceProtocol?.statusBar(hide: true, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(foreground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
         globalMainInterfaceProtocol?.statusBar(hide: true, animated: false)
        
        getCurrentCell()?.isCurrentItem = true
        getCurrentCell()?.resume()

        self.navigationController?.delegate = transitionController
        
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                    longPressGR.require(toFail: panGestureRecognizer)
                    longPressGR.require(toFail: collectionView.panGestureRecognizer)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        for cell in collectionView.visibleCells as! [StoryViewController] {
            cell.pause()
        }
        
        startIndex = getCurrentCell()?.viewIndex
        NotificationCenter.default.removeObserver(self)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        for cell in collectionView.visibleCells as! [StoryViewController] {
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
        
        let layout = AnimatedCollectionViewLayout()
        layout.itemSize = UIScreen.main.bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        layout.animator = CubeAttributesAnimator()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        collectionView.register(StoryViewController.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.black
        collectionView.bounces = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.isOpaque = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.reloadData()
        
        view.addSubview(collectionView)
                longPressGR = TimedLongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGR.minimumPressDuration = 0.0
        
        longPressGR.delegate = self
        
        self.view.addGestureRecognizer(longPressGR)
        
    }
    
    func appMovedToBackground() {
        dismissPopup(false)
    }
    
    func foreground() {
        getCurrentCell()?.setOverlays()
    }
    
    func handleLongPress(gestureReconizer: TimedLongPressGestureRecognizer) {
        
        guard let cell = getCurrentCell() else { return }
        let tappedPoint = gestureReconizer.location(in: view)
        
        let prevItem = tappedPoint.x < view.frame.width * 0.25
        if gestureReconizer.state == .began {
            gestureReconizer.startTime = Date()
            if prevItem {
                cell.prevView.alpha = 1.0
            } else {
                
            }
        }
        if gestureReconizer.state == .changed {
             let duration = Date().timeIntervalSince(gestureReconizer.startTime!)
            if duration >= 0.5 {
                cell.focus(true)
            }
        }
        if gestureReconizer.state == UIGestureRecognizerState.ended {
            let duration = Date().timeIntervalSince(gestureReconizer.startTime!)
            if prevItem {
                UIView.animate(withDuration: 0.3, animations: {
                    cell.prevView.alpha = 0.0
                })
            }
            if duration < 0.5 {
                if cell.keyboardUp {
                    //cell.commentBar.textField.resignFirstResponder()
                    return
                }
                if prevItem {
                  cell.prevItem()
                } else {
                    cell.nextItem()
                }
            } else {
                cell.focus(false)
            }
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let cell = getCurrentCell() else { return false }
        let keyboardUp = cell.keyboardUp
        
        let point = gestureRecognizer.location(ofTouch: 0, in: self.view)
        let authorBottomY = cell.headerView.frame.origin.y + cell.headerView.frame.height
        let commentsTableHeight = cell.commentsView.getTableHeight()
        let commentsTopY = cell.infoView.frame.origin.y - commentsTableHeight
        
        if keyboardUp {
            if point.y > commentsTopY {
                return false
            }
        }
        
        
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
            
            if keyboardUp {
                if translate.y > 0 {
                    cell.commentBar.textField.resignFirstResponder()
                }
                return false
            } else {
                if translate.y < 0 {
                    cell.commentBar.textField.becomeFirstResponder()
                }
            }
            
            return Double(abs(translate.y)/abs(translate.x)) > Double.pi / 4 && translate.y > 0
        }
        
        if let _ = gestureRecognizer as? UILongPressGestureRecognizer  {
            if keyboardUp {
                return false
            }
            let goodzone = point.y < commentsTopY && point.y > authorBottomY
            return goodzone
        }
        
        return false
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.main.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stories.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: StoryViewController = collectionView.dequeueReusableCell(withReuseIdentifier: "presented_cell", for: indexPath as IndexPath) as! StoryViewController
        cell.delegate = self
        
        cell.prepareStory(withStory: stories[indexPath.item], cellIndex: indexPath.item, atIndex: startIndex)
        
        if firstCell {
            firstCell = false
        }
        
        startIndex = nil
        cell.clipsToBounds = true
        
        return cell
    }

    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        

        var visibleRect = CGRect()
        
        visibleRect.origin = collectionView.contentOffset
        visibleRect.size = collectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath: IndexPath = collectionView.indexPathForItem(at: visiblePoint)!
        
        currentIndexPath = visibleIndexPath
        
        
        getCurrentCell()?.resume()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! StoryViewController
        cell.shouldAutoPause = true
        //cell.pause()
    }
    
    func getCurrentCell() -> StoryViewController? {
        if let index = currentIndexPath {
            if let cell = collectionView.cellForItem(at: index) as? StoryViewController {
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
    var shouldScrollToBottom = false

}

extension StoriesViewController: StoryCommentsProtocol {
    func dismissComments() {
        
    }
    
    func dismissStory() {
        dismissPopup(true)
    }
    
    func replyToUser(_ username:String) {

    }

}

extension StoriesViewController: PopupProtocol {

    func dismissPopup(_ animated:Bool) {
        getCurrentCell()?.pause()
        getCurrentCell()?.destroyVideoPlayer()
        if let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first {
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
            navigationController?.popViewController(animated: animated)
        }
    }
    
    func showAnonOptions(_ aid: String) {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
        cell.pause()
        if let my_aid = userState.anonID, my_aid != aid {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                cell.resume()
            }
            actionSheet.addAction(cancelActionButton)
            
            //            let messageAction: UIAlertAction = UIAlertAction(title: "Send Message", style: .default) { action -> Void in
            //
            //            }
            //            actionSheet.addAction(messageAction)
            
            let blockAction: UIAlertAction = UIAlertAction(title: "Block", style: .destructive) { action -> Void in
                UserService.blockAnonUser(aid: aid) { success in
                    print("Success: \(success)")
                    cell.resume()
                }
            }
            
            actionSheet.addAction(blockAction)
            
            let reportAction: UIAlertAction = UIAlertAction(title: "Report User", style: .destructive) { action -> Void in
                let reportSheet = UIAlertController(title: nil, message: "Why are you reporting this user?", preferredStyle: .actionSheet)
                reportSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                reportSheet.addAction(UIAlertAction(title: "Harassment", style: .destructive, handler: { _ in
                    UserService.reportAnonUser(aid: aid, type: .Harassment, completion: { success in })
                }))
                reportSheet.addAction(UIAlertAction(title: "Bot", style: .destructive, handler: { _ in
                    UserService.reportAnonUser(aid: aid, type: .Bot, completion: { success in })
                }))
                self.present(reportSheet, animated: true, completion: nil)
            }
            
            actionSheet.addAction(reportAction)
            
            self.present(actionSheet, animated: true, completion: nil)
            
        }
    }
    
    func keyboardStateChange(_ up: Bool) {
        collectionView.isScrollEnabled = !up
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
    
    func showRegion(_ region: City) {
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = CityViewController()
        controller.region = region
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    
    func showMetaLikes() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
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
        guard let item = cell.item else { return }
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = PostMetaTableViewController()
        controller.itemStateController = cell.itemStateController
        controller.item = item
        controller.mode = .comments
        globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
    }
    
    func showMore() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
        cell.pause()
        
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
        
        if isCurrentUserId(id: item.authorId) {
            let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive) { action -> Void in
                UploadService.deleteItem(item: item) { success in
                    if success {
                        self.dismissPopup(true)
                    }
                }
            }
            actionSheet.addAction(deleteAction)
        } else {
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
            
        }
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }

}

extension StoriesViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        getCurrentCell()?.pause()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
}

extension StoriesViewController: View2ViewTransitionPresented {
    
    func destinationFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }
    
    func destinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
        if let cell: StoryViewController = self.collectionView.cellForItem(at: indexPath) as? StoryViewController
        {
            //cell.prepareForTransition(isPresenting: isPresenting)
        }
        return view
        
    }
    
    func prepareDestinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) {
        
        if isPresenting {
            if let indexPath: IndexPath = userInfo!["destinationIndexPath"] as? IndexPath {
                currentIndexPath = indexPath
                let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
                self.collectionView.contentOffset = contentOffset
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
            }
        }
    }
}


class TimedLongPressGestureRecognizer : UILongPressGestureRecognizer {
    var startTime : Date?
}



