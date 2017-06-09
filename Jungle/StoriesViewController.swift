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
    
    var closeButton:UIButton!
    
    var collectionTap:UITapGestureRecognizer!
    
    
    fileprivate var commentBar:CommentBar!
    fileprivate var scrollView:UIScrollView!
    fileprivate var commentsViewController:CommentsViewController!
    
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
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardDidDisappear), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
 }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
         globalMainInterfaceProtocol?.statusBar(hide: true, animated: false)
        
        if let cell = getCurrentCell() {
            cell.resume()            
            if let item = cell.item {
                commentsViewController.setupItem(item)
            }
        }
        self.navigationController?.delegate = transitionController
        
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                    scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
                    
                    scrollView.isScrollEnabled = !commentBar.textField.isFirstResponder
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
        self.view.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
        
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
        
        collectionView.register(StoryViewController.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.white
        collectionView.bounces = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.isOpaque = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.reloadData()
        
        collectionContainerView.addSubview(collectionView)
        collectionContainerView.applyShadow(radius: 5.0, opacity: 0.25, height: 0.0, shouldRasterize: false)
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height * 2.0)
        
        self.scrollView.addSubview(collectionContainerView)
        self.view.addSubview(scrollView)
        scrollView.isPagingEnabled = true
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        scrollView.bounces = false
        scrollView.canCancelContentTouches = false
        scrollView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        
        commentsViewController = CommentsViewController()
        commentsViewController.delegate = self
        commentsViewController.view.frame = CGRect(x: 0, y: view.frame.height * 1.23, width: view.frame.width, height: view.frame.height * 0.77)
        commentsViewController.setup()
        
        self.addChildViewController(commentsViewController)
        self.scrollView.addSubview(commentsViewController.view)
        commentsViewController.didMove(toParentViewController: self)
        
        commentBar = UINib(nibName: "CommentBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentBar
        commentBar.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 50.0)
        commentBar.textField.delegate = self
        commentBar.delegate = self
        commentBar.textField.addTarget(self, action: #selector(commentTextChanged), for: .editingChanged)
        
        self.view.addSubview(commentBar)
        
        longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGR.minimumPressDuration = 0.33
        
        longPressGR.delegate = self
        self.view.addGestureRecognizer(longPressGR)
        
        tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGR.delegate = self
        self.view.addGestureRecognizer(tapGR)
        
        closeButton = UIButton(frame: CGRect(x: view.frame.width - 50.0, y: 0, width: 50, height: 50))
        closeButton.setImage(UIImage(named: "delete_thin"), for: .normal)
        closeButton.setTitleColor(UIColor.black, for: .normal)
        closeButton.tintColor = UIColor.black
        closeButton.alpha = 0.0
        
        closeButton.addTarget(self, action: #selector(dismissComments), for: .touchUpInside)
        self.view.addSubview(closeButton)

        collectionTap = UITapGestureRecognizer(target: self, action: #selector(dismissComments))
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

        if let tap = gestureRecognizer as? UITapGestureRecognizer  {
            let point = tap.location(in: self.view)
            return point.y > 90.0 && scrollView.contentOffset.y == 0
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
            return Double(abs(translate.y)/abs(translate.x)) > Double.pi / 4 && translate.y > 0
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
        
        if scrollView == self.scrollView {
            
            if scrollView.contentOffset.y == 0 {
                self.collectionContainerView.removeGestureRecognizer(collectionTap)
                self.collectionView.isScrollEnabled = true
            } else {
                self.collectionContainerView.addGestureRecognizer(collectionTap)
                self.collectionView.isScrollEnabled = false
            }
            
            return
        }
        
        var visibleRect = CGRect()
        
        visibleRect.origin = collectionView.contentOffset
        visibleRect.size = collectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath: IndexPath = collectionView.indexPathForItem(at: visiblePoint)!
        
        currentIndexPath = visibleIndexPath
        
        //SHOULD HANDLE COMMENTS VIEW AS WELL
        
        if let cell = getCurrentCell() {
            cell.resume()
            if let item = cell.item {
                commentsViewController.setupItem(item)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! StoryViewController
        cell.reset()
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
        if scrollView.isScrollEnabled {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        } else {
            commentBar.textField.resignFirstResponder()
        }
    }
    
    func dismissStory() {
        dismissPopup(true)
    }
    
    func replyToUser(_ username:String) {
        if username == mainStore.state.userState.user?.username { return }
        
        self.commentBar.textField.text = "@\(username) "
        self.commentBar.textField.becomeFirstResponder()
    }
}

extension StoriesViewController: CommentBarProtocol {
    func sendComment(_ text:String) {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
        commentBar.textField.text = ""
        commentBar.sendLabelState(false)
        UploadService.addComment(post: item, comment: text) { success in }
        commentBar.textField.resignFirstResponder()
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
        scrollView.setContentOffset(CGPoint(x: 0, y:self.view.frame.height), animated: true)
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
        if let item = getCurrentCell()?.item {
            commentsViewController.header.setCurrentUserMode(item.authorId == mainStore.state.userState.uid)
        }
        
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
    
    func keyboardDidDisappear(notification :NSNotification) {
        scrollView.isScrollEnabled = true
    }
    
    
}

extension StoriesViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            getCurrentCell()?.pause()
            return
        }
        if scrollView !== self.scrollView { return }
        let yOffset = scrollView.contentOffset.y
        let progress = yOffset/view.frame.height
        let reverseProgress = 1 - progress
        let progressMultiple = progress * progress * progress * progress * progress
        
        closeButton.alpha = progressMultiple
        
        collectionContainerView.transform = CGAffineTransform(scaleX: reverseProgress * 0.5 + 0.5, y: reverseProgress * 0.5 + 0.5)
        collectionContainerView.transform = CGAffineTransform(translationX: 0.0, y: view.frame.height/2.0)
        let scale = CGAffineTransform(scaleX: reverseProgress * 0.8 + 0.20, y: reverseProgress * 0.8 + 0.20)
        let translate = CGAffineTransform(translationX: 0.0, y: view.frame.height * (progress) * 0.6125)
        collectionContainerView.transform = scale.concatenating(translate)
        
        
        var barFrame = commentBar.frame
        barFrame.origin.y = view.frame.height - 50.0 * (progress * progress)
        commentBar.frame = barFrame
        
        if let cell = getCurrentCell() {
            if yOffset > 0 {
                cell.looping = true
            } else {
                cell.looping = false
            }
            
            cell.setDetailFade(reverseProgress)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
    
}

extension StoriesViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 140 // Bool
    }
    
    func commentTextChanged (_ target: UITextField){
        switch target {
        case commentBar.textField:
            if let text = target.text, text != "" {
                commentBar.sendLabelState(true)
            } else {
                commentBar.sendLabelState(false)
            }
            break
        default:
            break
        }
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




