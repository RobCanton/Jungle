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

protocol PopupProtocol {
    func showDeleteOptions()
    func showOptions()
    func showComments()
    func dismissPopup(_ animated:Bool)
}

class PostCollectionViewController:UIViewController {
    weak var transitionController: TransitionController!
    
}

class StoriesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    weak var transitionController: TransitionController!
    var storyType:StoryType = .PlaceStory
    
    var label:UILabel!
    var locationStories = [LocationStory]()
    var stories = [Story]()
    
    var userStories = [UserStory]()
    
    var currentIndex:IndexPath!
    var collectionView:UICollectionView!
    
    var longPressGR:UILongPressGestureRecognizer!
    var tapGR:UITapGestureRecognizer!
    
    var location:Location?

    var firstCell = true
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if self.navigationController!.delegate !== transitionController {
            self.collectionView.reloadData()
        }
        
        globalMainRef?.statusBar(hide: true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
         globalMainRef?.statusBar(hide: true, animated: false)
        self.navigationController?.delegate = transitionController
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
        }
        
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
        
        collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
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
        self.view.addSubview(collectionView)
        
        label = UILabel(frame: CGRect(x:0,y:0,width:self.view.frame.width,height:100))
        label.textColor = UIColor.white
        label.center = view.center
        label.textAlignment = .center
        
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
        
        if cell.commentsActive { return false }
        
        if let _ = gestureRecognizer as? UITapGestureRecognizer  {
            return true
        }

        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as IndexPath
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?

            let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
            if translate.y < 0 {
                if translate.y < -3 {
                    cell.showComments()
                }
                return false
            }
            return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
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
        cell.contentView.backgroundColor = UIColor.black
        cell.delegate = self
        if storyType == .UserStory {
            cell.prepareStory(withStory: userStories[indexPath.item])
        } else {
            cell.prepareStory(withLocation: locationStories[indexPath.item])
        }
        if firstCell {
            firstCell = false
        }
        
        return cell
    }
    
    func getCurrentCellIndex() -> IndexPath {
        return collectionView.indexPathsForVisibleItems[0]
    }
    
    func stopPreviousItem() {
        if let cell = getCurrentCell() {
            cell.pauseVideo()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        
        let newItem = Int(xOffset / self.collectionView.frame.width)
        currentIndex = IndexPath(item: newItem, section: 0)
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! StoryViewController
    
        cell.reset()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
}

extension StoriesViewController: PopupProtocol {
    func dismissPopup(_ animated:Bool) {
        getCurrentCell()?.pauseVideo()
        getCurrentCell()?.destroyVideoPlayer()
        if let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as? IndexPath {
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
            navigationController?.popViewController(animated: animated)
        }
    }
    
    func showUser(_ uid:String) {
        if let nav = self.navigationController {
            nav.delegate = nil
        }
        let controller = UIViewController()
        controller.title = title
        controller.view.backgroundColor = UIColor.white
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showUsersList(_ uids:[String], _ title:String) {
        
    }
    
    func showDeleteOptions() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else {
            cell.resumeStory()
            return }
        if item.getAuthorId() != mainStore.state.userState.uid { return }
        cell.pauseStory()
        
        
        let actionSheet = UIAlertController(title: "Delete post?", message: nil, preferredStyle: .alert)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            cell.resumeStory()
        }
        actionSheet.addAction(cancelActionButton)
        
        let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive) { action -> Void in
            
            UploadService.deleteItem(item: item, completion: { success in
                if success {
                    self.dismissPopup(true)
                }
            })
        }
        actionSheet.addAction(deleteActionButton)
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func showOptions() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else {
            cell.resumeStory()
            return }
        
        if item.getAuthorId() == mainStore.state.userState.uid {
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                cell.resumeStory()
            }
            actionSheet.addAction(cancelActionButton)
            
            let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive) { action -> Void in
                
                /*UploadService.deleteItem(item: item, completion: { success in
                 if success {
                 self.dismissPopup(true)
                 }
                 })*/
            }
            actionSheet.addAction(deleteActionButton)
            
            self.present(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                cell.resumeStory()
            }
            actionSheet.addAction(cancelActionButton)
            
            let OKAction = UIAlertAction(title: "Report", style: .destructive) { (action) in
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                    cell.resumeStory()
                }
                alertController.addAction(cancelAction)
                
                let OKAction = UIAlertAction(title: "It's Inappropriate", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Inappropriate, showNotification: true, completion: { success in
                        if success {
                            let reportAlert = UIAlertController(title: "Report Sent.",
                                                                message: "Thanks for lettings us know. We will act upon this report within 24 hours.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { action -> Void in
                                cell.resumeStory()
                            }))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        } else {
                            let reportAlert = UIAlertController(title: "Report Failed to Send.",
                                                                message: "Please try again.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { action -> Void in
                                cell.resumeStory()
                            }))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        }
                        
                        
                    })
                }
                alertController.addAction(OKAction)
                
                let OKAction2 = UIAlertAction(title: "It's Spam", style: .destructive) { (action) in
                    UploadService.reportItem(item: item, type: ReportType.Spam, showNotification: true, completion: { success in
                        if success {
                            let reportAlert = UIAlertController(title: "Report Sent",
                                                                message: "Thanks for lettings us know. We will act upon this report within 24 hours.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { action -> Void in
                                cell.resumeStory()
                            }))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        } else {
                            let reportAlert = UIAlertController(title: "Report Failed to Send",
                                                                message: "Please try again.", preferredStyle: .alert)
                            reportAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { action -> Void in
                                cell.resumeStory()
                            }))
                            
                            self.present(reportAlert, animated: true, completion: nil)
                        }
                        
                        
                    })
                }
                alertController.addAction(OKAction2)
                
                self.present(alertController, animated: true, completion: nil)
            }
            actionSheet.addAction(OKAction)
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func showComments() {
        
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
        let controller = CommentsViewController()
        controller.title = "Comments"
        controller.storyRef = cell
        controller.item = item
        if item.comments.count == 0 {
            controller.shouldShowKeyboard = true
        }
        
        let nav = UINavigationController(rootViewController: controller)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.tintColor = UIColor.black
        
        nav.modalPresentationStyle = .overCurrentContext
        globalMainRef?.statusBar(hide: false, animated: true)
        self.present(nav, animated: true, completion: nil)
        
    }
    
    
    func getCurrentCell() -> StoryViewController? {
        if let cell = collectionView.visibleCells.first as? StoryViewController {
            return cell
        }
        return nil
    }
}

extension StoriesViewController: View2ViewTransitionPresented {
    
    func destinationFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }
    
    func destinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
        let cell: StoryViewController = self.collectionView.cellForItem(at: indexPath) as! StoryViewController
        
        cell.prepareForTransition(isPresenting: isPresenting)
        
        return view
        
    }
    
    func prepareDestinationView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) {
        
        if isPresenting {
            let indexPath: IndexPath = userInfo!["destinationIndexPath"] as! IndexPath
            currentIndex = indexPath
            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOffset
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
}




