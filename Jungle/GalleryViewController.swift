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
    
    var uid:String!
    var label:UILabel!
    var posts = [StoryItem]()
    var currentIndex:IndexPath!
    var collectionView:UICollectionView!
    
    var isSingleItem = false
    var showCommentsOnAppear = false
    
    var statusBarShouldHide = false
    var shouldScrollToBottom = false
    
    fileprivate var commentBar:CommentBar!
    fileprivate var scrollView:UIScrollView!
    fileprivate var commentsViewController:CommentsViewController!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if self.navigationController!.delegate !== transitionController {
            self.collectionView.reloadData()
        }
        globalMainRef?.statusBar(hide: true, animated: false)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if showCommentsOnAppear {
            showCommentsOnAppear = false
            scrollView.setContentOffset(CGPoint(x: 0, y: view.frame.height), animated: false)
            getCurrentCell()?.setDetailFade(0.0)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
        
        self.navigationController?.delegate = transitionController
        
        if let cell = getCurrentCell() {
            if scrollView.contentOffset.y == 0 {
                cell.resume()
            }
            
            if let item = cell.storyItem {
                commentsViewController.setupItem(item)
            }
        }
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                    scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
                    scrollView.isScrollEnabled = true
                }
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        for cell in collectionView.visibleCells as! [PostViewController] {
            //cell.yo()
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
        
        collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
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
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height * 2.0)
        
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
        commentsViewController.view.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height)
        
        self.addChildViewController(commentsViewController)
        self.scrollView.addSubview(commentsViewController.view)
        commentsViewController.didMove(toParentViewController: self)
        
        commentBar = UINib(nibName: "CommentBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentBar
        commentBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        commentBar.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 50.0)
        
        commentBar.textField.delegate = self
        
        self.view.addSubview(commentBar)
        
        label = UILabel(frame: CGRect(x:0,y:0,width:self.view.frame.width,height:100))
        label.textColor = UIColor.white
        label.center = view.center
        label.textAlignment = .center
    }
    
    func appMovedToBackground() {
        dismissPopup(false)
    }
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let cell = getCurrentCell() else { return false }
        if cell.keyboardUp {
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
        
        if scrollView.contentOffset.y != 0 {
            return false
        }

        
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
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
        cell.storyItem = posts[indexPath.item]
        return cell
    }
    
    func getCurrentCell() -> PostViewController? {
        if let cell = collectionView.visibleCells.first as? PostViewController {
            return cell
        }
        return nil
    }
    
    func stopPreviousItem() {
        if let cell = getCurrentCell() {
            cell.pauseVideo()
        }
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
        
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != collectionView { return }
        //SHOULD HANDLE COMMENTS VIEW AS WELL
        
        let xOffset = scrollView.contentOffset.x
        let newItem = Int(xOffset / self.collectionView.frame.width)
        currentIndex = IndexPath(item: newItem, section: 0)
        
        if let cell = getCurrentCell() {
            cell.resume()
            if let item = cell.storyItem {
                commentsViewController.setupItem(item)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! PostViewController
        cell.reset()
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
}

extension GalleryViewController: PopupProtocol {
    
    func newItem(_ item: StoryItem) {
        commentsViewController.setupItem(item)
    }
    
    
    func dismissPopup(_ animated:Bool) {
        getCurrentCell()?.pauseVideo()
        getCurrentCell()?.destroyVideoPlayer()
        if let indexPath: IndexPath = self.collectionView.indexPathsForVisibleItems.first! as? IndexPath {
            let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! IndexPath
            if !isSingleItem {
                self.transitionController.userInfo!["initialIndexPath"] = IndexPath(item: indexPath.item, section: initialPath.section) as AnyObject?
            }
            self.transitionController.userInfo!["destinationIndexPath"] = indexPath as AnyObject?
            
            navigationController?.popViewController(animated: animated)
        }
    }
    
    func showUser(_ uid:String) {
        
    }
    
    
    func showOptions() {
    }
    
    func showComments() {
        scrollView.setContentOffset(CGPoint(x: 0, y:self.view.frame.height), animated: true)
    }
    
    
    func sendComment(_ comment: String) {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.storyItem else { return }
        UploadService.addComment(post: item, comment: comment)
        commentBar.textField.resignFirstResponder()
    }
    
    func keyboardWillAppear(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        scrollView.isScrollEnabled = false
        commentsViewController.setInfoMode(.Comments)
        commentsViewController.header.setCurrentUserMode(false)
        
        self.commentBar.sendButton.isEnabled = true
        
        let height = self.view.frame.height
        let textViewFrame = self.commentBar.frame
        let textViewY = height - keyboardFrame.height - textViewFrame.height
        
        let table = self.commentsViewController.tableView!
        var tableFrame = table.frame
        let tableContainerStart:CGFloat = table.superview!.frame.origin.y
        let tableContentBottom = table.contentSize.height + tableContainerStart
        
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
        if let item = getCurrentCell()?.storyItem {
            commentsViewController.header.setCurrentUserMode(item.getAuthorId() == mainStore.state.userState.uid)
        }
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
    
    func showDeleteOptions() {
        
    }
}


extension GalleryViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            getCurrentCell()?.pause()
            return
        }
        if scrollView !== self.scrollView { return }
        let yOffset = scrollView.contentOffset.y
        let alpha = 1 - yOffset/view.frame.height
        let multiple = alpha * alpha
        
        let ra = yOffset/view.frame.height
        let ry = ra * ra
        var cFrame = collectionView.frame
        cFrame.origin.y = yOffset
        collectionView.frame = cFrame
        
        var barFrame = commentBar.frame
        barFrame.origin.y = view.frame.height - 50.0 * (ry)
        commentBar.frame = barFrame
        
        if let cell = getCurrentCell() {
            if yOffset > 0 {
                cell.pause()
            } else {
                cell.resume()
            }
            
            cell.setDetailFade(alpha)
            collectionView.alpha = 0.75 + 0.25 * alpha
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
}

extension GalleryViewController: UITextFieldDelegate {
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
            currentIndex = indexPath
            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOffset
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
}

