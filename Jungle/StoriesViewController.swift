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
    func newItem(_ item:StoryItem)
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
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
         globalMainRef?.statusBar(hide: true, animated: false)
        self.navigationController?.delegate = transitionController
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
            if let item = cell.item {
               commentsViewController.setupItem(item)
            }
        }
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                    scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
                    //scrollView.panGestureRecognizer.require(toFail: collectionView.panGestureRecognizer)
                    scrollView.isScrollEnabled = true
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
    
    fileprivate var commentBar:CommentBar!
    fileprivate var scrollView:UIScrollView!
    fileprivate var commentsViewController:CommentsViewController!
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
        collectionView.reloadData()
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height * 2.0)
        
//        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
//        blurView.frame = v2.bounds
//        v2.addSubview(blurView)
        
        self.scrollView.addSubview(collectionView)
        self.view.addSubview(scrollView)
        scrollView.isPagingEnabled = true
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        scrollView.bounces = false
        scrollView.canCancelContentTouches = false
        scrollView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        
        commentsViewController = CommentsViewController()
        commentsViewController.handleDismiss = handleDismiss
        commentsViewController.view.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height)
        
        self.addChildViewController(commentsViewController)
        self.scrollView.addSubview(commentsViewController.view)
        commentsViewController.didMove(toParentViewController: self)
        
        commentBar = UINib(nibName: "CommentBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentBar
        commentBar.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 50.0)
        commentBar.textField.delegate = self
        commentBar.sendHandler = sendComment
        
        self.view.addSubview(commentBar)
        
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
            
            if scrollView.contentOffset.y != 0 {
                return false
            }
            
            let translate: CGPoint = panGestureRecognizer.translation(in: self.view)
            if translate.y < 0 {
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
            if let item = cell.item {
                commentsViewController.setupItem(item)
            }
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
    var shouldScrollToBottom = false
    
    var redbar:UIView?
    var greenBar:UIView?
}

extension StoriesViewController: PopupProtocol {
    
    func newItem(_ item:StoryItem) {
        commentsViewController.setupItem(item)
    }
    
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
    
    
    
    func sendComment(_ comment: String) {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
        print("SEND COMMENT: \(comment)")
        UploadService.addComment(post: item, comment: comment)
        //shouldScrollToBottom = true
        commentBar.textField.resignFirstResponder()
    }
    
    func keyboardWillAppear(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        scrollView.isScrollEnabled = false
        
        self.commentBar.sendButton.isEnabled = true
        
        let height = self.view.frame.height
        let textViewFrame = self.commentBar.frame
        let textViewY = height - keyboardFrame.height - textViewFrame.height
        
        let table = self.commentsViewController.tableView!
        var tableFrame = table.frame
        let tableContainerStart:CGFloat = table.superview!.frame.origin.y
        let tableContentBottom = table.contentSize.height + tableContainerStart
        print("tableContentBottom: \(tableContentBottom) | textViewY: \(textViewY)")
        
        
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in

            self.commentBar.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)
            
            self.commentBar.sendButton.alpha = 1.0
            
            if tableContentBottom >= tableFrame.height {
                let diff = tableContentBottom - textViewY
                let max = min(diff, textViewY)
                tableFrame.origin.y =  -keyboardFrame.height//tableContainerStart - textViewY//max//textViewY - tableFrame.height - table.superview!.frame.origin.y
                table.frame = tableFrame
            }
            
        })
    }
    
    
    func keyboardWillDisappear(notification: NSNotification){
        
        self.commentBar.sendButton.isEnabled = false
        
        scrollView.isScrollEnabled = true
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
            let height = self.view.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewStart = height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)
            
            let table = self.commentsViewController.tableView!
            var tableFrame = table.frame
            tableFrame.origin.y = 0
            table.frame = tableFrame
            
        }, completion: { _ in
            if self.shouldScrollToBottom {
                self.shouldScrollToBottom = false
                self.commentsViewController.scrollBottom(animated: true)
            }
        })
    }
    
    func handleDismiss() {
        if scrollView.isScrollEnabled {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        } else {
            commentBar.textField.resignFirstResponder()
        }
    }
    
    
    func getCurrentCell() -> StoryViewController? {
        if let cell = collectionView.visibleCells.first as? StoryViewController {
            return cell
        }
        return nil
    }
    
    
}

extension StoriesViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView !== self.scrollView { return }
        let yOffset = scrollView.contentOffset.y
        let alpha = 1 - yOffset/view.frame.height
        let multiple = alpha * alpha * alpha * alpha * alpha
        
        let ra = yOffset/view.frame.height
        let ry = ra * ra
        print("yOffset: \(yOffset)")
        var cFrame = collectionView.frame
        cFrame.origin.y = yOffset
        collectionView.frame = cFrame
        
        var barFrame = commentBar.frame
        barFrame.origin.y = view.frame.height - 50.0 * (ry)
        commentBar.frame = barFrame
        
        if let cell = getCurrentCell() {
            if yOffset > 0 {
                cell.pauseStory()
                cell.progressBar?.resetActiveIndicator()
            } else {
                //cell.progressBar?.resetActiveIndicator()
                cell.setupItem()
                cell.resumeStory()
            }
            
            cell.setDetailFade(multiple)
            collectionView.alpha = 0.5 + 0.5 * alpha
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
}

extension StoriesViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if !text.isEmpty {
                textField.text = ""
                sendComment(text)
            }
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 140 // Bool
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




