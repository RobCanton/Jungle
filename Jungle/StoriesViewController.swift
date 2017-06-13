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

protocol PopupProtocol: class {
    func showComments()
    func showMore()
    func editCaption()
    func showUser(_ uid:String)
    func showPlace(_ location:Location) 
    func dismissPopup(_ animated:Bool)
    func keyboardStateChange(_ up:Bool)
}

class StoriesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    weak var transitionController: TransitionController!
    var storyType:StoryType = .UserStory
    
    var locationStories = [LocationStory]()
    var stories:[Story]!
    var userStories = [UserStory]()
    
    var collectionContainerView:UIView!
    var collectionView:UICollectionView!
    
    var longPressGR:UILongPressGestureRecognizer!
    var tapGR:UITapGestureRecognizer!
    var firstCell = true
    
    var currentIndexPath:IndexPath?
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
        
        getCurrentCell()?.resume()

        self.navigationController?.delegate = transitionController
        
        
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
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = UIScreen.main.bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        collectionView.register(StoryViewController.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.black
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.isOpaque = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.reloadData()
        
        view.addSubview(collectionView)
                longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGR.minimumPressDuration = 0.33
        
        longPressGR.delegate = self
        self.view.addGestureRecognizer(longPressGR)
        
        tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGR.delegate = self
        self.view.addGestureRecognizer(tapGR)
        
    }
    
    func appMovedToBackground() {
        dismissPopup(false)
    }
    
    func foreground() {
        getCurrentCell()?.setOverlays()
    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == .began {

        }
        if gestureReconizer.state == UIGestureRecognizerState.ended {

        }
    }
    
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        getCurrentCell()?.tapped(gesture: gestureRecognizer)
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
        
        if let _ = gestureRecognizer as? UITapGestureRecognizer  {
            return true
        }
        
        if let _ = gestureRecognizer as? UILongPressGestureRecognizer  {
            return true
        }
        
        let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath

        self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.main.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if storyType == .UserStory {
            return userStories.count
        }
        return locationStories.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: StoryViewController = collectionView.dequeueReusableCell(withReuseIdentifier: "presented_cell", for: indexPath as IndexPath) as! StoryViewController
        cell.delegate = self
        if storyType == .UserStory {
            
            cell.prepareStory(withStory: userStories[indexPath.item], cellIndex: indexPath.item, atIndex: startIndex)
        } else {
            cell.prepareStory(withLocation: locationStories[indexPath.item], cellIndex: indexPath.item,  atIndex: startIndex)
        }
        if firstCell {
            firstCell = false
        }
        
        startIndex = nil
        
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
    func showMore() {
        
    }
    
    func editCaption() {
        
    }


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
    
    }
    
    func showUsersList(_ uids:[String], _ title:String) {}
    
    func showComments() {
        
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




