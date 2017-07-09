
//
//  StoryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import NVActivityIndicatorView


public class StoryViewController: UICollectionViewCell, StoryProtocol, PostHeaderProtocol, UIScrollViewDelegate, ItemStateProtocol,
    CommentItemBarProtocol, PostCaptionProtocol, CommentsTableProtocol {

    private(set) var viewIndex = 0
    var returnIndex:Int?
    private(set) var cellIndex:Int?
    weak var story:Story!
    weak var item:StoryItem?
    weak var delegate:PopupProtocol?
    var activityView:NVActivityIndicatorView!
    
    var progressBar:StoryProgressIndicator?
    
    var playerLayer:AVPlayerLayer?
    var currentProgress:Double = 0.0
    var timer:Timer?
    
    var totalTime:Double = 0.0
    var subscribedToPost = false
    var shouldAutoPause = true
    
    var editCaptionMode = false
    var keyboardUp = false
    var flagLabel:UILabel?
    
    var itemStateController:ItemStateController!
    
    func addFlagLabel() {
       
    }
    
    deinit { print("Deinit >> StoryViewController") }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(gradientView)
        contentView.addSubview(prevView)
        
        /* Info view */
        infoView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - infoView.frame.height,width: self.frame.width,height: 0)
        contentView.addSubview(infoView)
        
        contentView.addSubview(commentBar)
        
        /* Comments view */
        commentsView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - commentsView.frame.height,width: commentsView.frame.width,height: commentsView.frame.height)
        contentView.addSubview(commentsView)
        
        videoContent.isHidden = true
        
        contentView.addSubview(guardView)
        
        contentView.addSubview(headerView)
        
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .ballBeat, color: UIColor.white, padding: 1.0)
        activityView.center = contentView.center
        contentView.addSubview(activityView)
        
        /* Item State Controller */
        itemStateController = ItemStateController()
        
    }
    
    func saveIndex() {
        returnIndex = viewIndex
    }
    
    func prepareStory(withStory story:Story, cellIndex: Int,  atIndex index:Int?) {
        clearStoryView()
        shouldAutoPause = true
        self.cellIndex = cellIndex
        viewIndex = index ?? 0
        self.story = story
        self.story.delegate = self
        story.determineState()
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func clearStoryView() {
        self.content.image = nil
        self.destroyVideoPlayer()
        self.headerView.clean()
    }
    
    func stateChange(_ state:UserStoryState) {
        switch state {
        case .notLoaded:
            story.downloadItems()
            break
        case .loadingItemInfo:
            break
        case .itemInfoLoaded:
            itemsLoaded()
            break
        case .loadingContent:
            break
        case .contentLoaded:
            itemsLoaded()
            break
        }
    }
    
    func sendComment(_ comment: String) {
        
        guard let item = self.item else { return }
        if comment == "" { return }
        commentBar.setBusyState(true)
        if editCaptionMode {
            
            self.commentBar.textField.resignFirstResponder()
            UploadService.editCaption(postKey: item.key, caption: comment) { success in
                self.commentBar.setBusyState(false)
                if success {
                    item.editCaption(caption: comment)
                }
                self.setOverlays()
            }
        } else {
            UploadService.addComment(post: item, comment: comment) { success in
                self.commentBar.setBusyState(false)
            }
        }
    }
    
    func toggleLike(_ like: Bool) {
        guard let item = self.item else { return }
        
        if like {
            UploadService.addLike(post: item)
            item.addLike(mainStore.state.userState.uid)
        } else {
            UploadService.removeLike(post: item)
            item.removeLike(mainStore.state.userState.uid)
        }
    }
    
    func showMore() {
        delegate?.showMore()
    }
    
    func editCaption() {
        guard let item = self.item else { return }
        editCaptionMode = true
        commentBar.textField.placeholder = "Edit Caption"
        commentBar.sendButton.setTitle("Set", for: .normal)
        commentBar.textField.becomeFirstResponder()
        commentBar.textField.text = item.caption
    }
    
    func showAuthor() {
        guard let item = self.item else { return }
        delegate?.showUser(item.authorId)
    }
    
    func showPlace(_ location: Location) {
        delegate?.showPlace(location)
    }
    
    func showUser(_ uid:String) {
        delegate?.showUser(uid)
    }
    
    func dismiss() {
        delegate?.dismissPopup(true)
    }
    
    func showMetaLikes() {
        delegate?.showMetaLikes()
    }
    
    func showMetaComments(_ indexPath:IndexPath?) {
        delegate?.showMetaComments(indexPath)
    }
    
    func liked(_ liked:Bool) {
        guard let item = self.item else { return }
        if liked {
            UploadService.addLike(post: item)
        } else {
            UploadService.removeLike(post: item)
        }
    }
    
    func refreshPulled() {
        itemStateController.retrievePreviousComments()
    }
    
    func animateIndicator() {
        self.content.alpha = 0.6
        self.activityView.startAnimating()
    }
    
    func stopIndicator() {
        self.content.alpha = 1.0
        self.activityView.stopAnimating()
    }
    
    
    func itemsLoaded() {
        
        let screenWidth: CGFloat = (UIScreen.main.bounds.size.width)
        let margin:CGFloat = 12.0
        
        progressBar?.removeFromSuperview()
        progressBar = StoryProgressIndicator(frame: CGRect(x: margin,y: margin, width: screenWidth - margin * 2,height: 1.5))
        progressBar!.createProgressIndicator(_story: story)
        contentView.addSubview(progressBar!)
        
        for item in story.items! {

            totalTime += item.length
        }
        
        if viewIndex >= story.items!.count{
            viewIndex = 0
        }
        
        self.setupItem()
        
    }
    
    func setupItem() {

        killTimer()
        pauseVideo()
        self.content.image = nil
        destroyVideoPlayer()

        guard let items = story.items else { return }
        if viewIndex >= items.count { return }
        
        let item = items[viewIndex]
        self.item = item

        guardView.isHidden = !item.shouldBlock
        content.image = UploadService.readImageFromFile(withKey: item.key)
        videoContent.isHidden = true
        
        itemStateController.removeAllObservers()
        itemStateController.delegate = self
        itemStateController.setupItem(item)
        
        
        setOverlays()
        
        let nextIndex = viewIndex + 1
        if nextIndex >= items.count { return }
        let nextItem = items[nextIndex]
        UploadService.retrievePostImageVideo(post: nextItem) { _ in }

    }
    
    func setOverlays() {
        guard let item = item else { return }
        
        commentBar.setup(item.authorId == mainStore.state.userState.uid)
        
        self.headerView.setup(item)
        self.headerView.delegate = self
        
        let width = self.frame.width - (10 + 8 + 8 + 32)
        var size:CGFloat = 0.0
        
        if let caption = item.caption, caption != "" {
            size =  UILabel.size(withText: caption, forWidth: width, withFont: UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)).height + 34
            infoView.isHidden = false
            commentsView.hasCaption = true
        } else {
            infoView.isHidden = true
            commentsView.hasCaption = false
        }
        
        infoView.frame = CGRect(x: 0, y: commentBar.frame.origin.y - size, width: frame.width, height: size)
        commentsView.frame = CGRect(x: 0, y: getCommentsViewOriginY(), width: commentsView.frame.width, height: commentsView.frame.height)
        commentsView.delegate = self
        
        self.infoView.setInfo(item)
        self.infoView.delegate = self
        
        commentsView.setTableComments(comments: item.comments, animated: false)
        commentBar.textField.delegate = self
        commentBar.delegate = self
        
        UploadService.addView(post: item)
        
    }
    
    func itemStateDidChange(likedStatus: Bool) {
        self.commentBar.setLikedStatus(likedStatus, animated: false)
    }
    
    func itemStateDidChange(numLikes: Int) {
        self.headerView.setNumLikes(numLikes)
    }
    
    func itemStateDidChange(numComments: Int) {
        self.headerView.setNumComments(numComments)
    }
    
    func itemStateDidChange(comments: [Comment]) {
        self.headerView.setNumComments(comments.count)
        self.commentsView.setTableComments(comments: comments, animated: true)
    }
    
    func itemStateDidChange(comments: [Comment], didRetrievePreviousComments: Bool) {
        
    }
    
    func itemStateDidChange(subscribed: Bool) {
        self.subscribedToPost = subscribed
        
    }
    
    func itemDownloading() {
        animateIndicator()
    }
    
    func itemDownloaded() {
        guard let item = item else { return }
        if let image = UploadService.readImageFromFile(withKey: item.key) {
            
            if item.contentType == .image {
                stopIndicator()
                setForPlay()
            }
            self.content.image = image
        } else {
            itemStateController.download()
        }
        
        
        if item.contentType == .video {
            
            if let videoURL = UploadService.readVideoFromFile(withKey: item.key) {
                stopIndicator()
                createVideoPlayer()
                let asset = AVAsset(url: videoURL)
                asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                    DispatchQueue.main.async {
                        let item = AVPlayerItem(asset: asset)
                        self.playerLayer?.player?.replaceCurrentItem(with: item)
                        self.setForPlay()
                    }
                })
            } else {
                itemStateController.download()
            }
        }
    }

    func setForPlay() {
        
        guard let item = self.item else { return }
        
        paused = false
        
        var itemLength = item.length
        if item.contentType == .video {
            videoContent.isHidden = false
            playVideo()
            
            if let currentItem = playerLayer?.player?.currentTime() {
                itemLength -= currentItem.seconds
            }
        }
        
        progressBar?.activateIndicator(itemIndex: viewIndex)
        
        timer = Timer.scheduledTimer(timeInterval: itemLength, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)

        if shouldAutoPause {
            shouldAutoPause = false
            pause()
        }
    }
    
    func nextItem() {
        guard let items = story?.items else { return }
        if !looping {
           viewIndex += 1
        }
        
        if viewIndex >= items.count {
            delegate?.dismissPopup(true)
        } else {
            setupItem()
        }
    }
    
    func prevItem() {
        guard let item = self.item else { return }
        guard let timer = self.timer else { return }
        let remaining = timer.fireDate.timeIntervalSinceNow
        let diff = remaining / item.length
        
        if diff > 0.75 {
            if viewIndex > 0 {
                viewIndex -= 1
            }
        }
        setupItem()
    }

    
    func createVideoPlayer() {
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: AVPlayer())
            playerLayer!.player?.actionAtItemEnd = .pause
            playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            playerLayer!.frame = videoContent.bounds
            self.videoContent.layer.addSublayer(playerLayer!)
        }
    }
    
    func destroyVideoPlayer() {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer?.player = nil
        self.playerLayer = nil
        videoContent.isHidden = false
        
    }

    func cleanUp() {
        pause()
        content.image = nil
        destroyVideoPlayer()
        killTimer()
        progressBar?.resetAllProgressBars()
        progressBar?.removeFromSuperview()
        delegate = nil
        item = nil
        returnIndex = nil
        itemStateController.removeAllObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    func reset() {
        progressBar?.resetActiveIndicator()
        shouldAutoPause = true
        pause()
    }
    
    var blockInappropriateContent = true
    
    func playVideo() {
        guard let _ = self.item else { return }
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        pauseVideo()
    }
    
    var looping = false
    var paused = false
    var remainingTime:TimeInterval?
    
    
    func pause() {
        if paused { return }
        itemStateController.delegate = nil
        paused = true
        pauseVideo()
        progressBar?.pauseActiveIndicator()
        guard let timer = self.timer else {
            remainingTime = nil
            return
        }
        remainingTime = timer.fireDate.timeIntervalSinceNow
        timer.invalidate()
    }

    
    func resume() {
        if !paused { return }
        paused = false
        progressBar?.hideAll(false)
        progressBar?.resumeActiveIndicator()
        guard let item = self.item else { return}
        itemStateController.delegate = self
        if item.needsDownload() {
            itemStateController.download()
        } else  {
            if remainingTime != nil {
                timer = Timer.scheduledTimer(timeInterval: remainingTime!, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)
                remainingTime = nil
            }
            if item.contentType == .video {
                playVideo()
            }
        }
        
    }
    
    
    func killTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func prepareForTransition(isPresenting:Bool) {
        progressBar?.hideAll(true)
        if isPresenting {
            content.isHidden = false
            videoContent.isHidden = true
        } else {
            pause()
        }
    }

    
    func tapped(gesture:UITapGestureRecognizer) {
        if keyboardUp {
            commentBar.textField.resignFirstResponder()
            return
        }
        
        guard let _ = item else { return }
        let tappedPoint = gesture.location(in: self)
        let width = self.bounds.width
        if tappedPoint.x < width * 0.25 {
            prevItem()
            prevView.alpha = 1.0
            UIView.animate(withDuration: 0.3, animations: {
                self.prevView.alpha = 0.0
            })
        } else {
            nextItem()
        }
    }
    
    func keyboardWillAppear(notification: NSNotification){
        keyboardUp = true
        //looping = true
        pause()
        itemStateController.delegate = self
        delegate?.keyboardStateChange(keyboardUp)
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        self.commentBar.likeButton.isUserInteractionEnabled = false
        self.commentBar.moreButton.isUserInteractionEnabled = false
        self.commentBar.sendButton.isUserInteractionEnabled = true
        self.commentsView.showTimeLabels(visible: true)
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            let height = self.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewY,width: textViewFrame.width,height: textViewFrame.height)
            
            self.commentsView.frame = CGRect(x: 0,y: self.getCommentsViewOriginY(),width: self.commentsView.frame.width,height: self.commentsView.frame.height)
            
            let infoFrame = self.infoView.frame
            let infoY = textViewY - infoFrame.height
            self.infoView.frame = CGRect(x: infoFrame.origin.x,y: infoY, width: infoFrame.width, height: infoFrame.height)
            
            self.commentBar.likeButton.alpha = 0.0
            self.commentBar.moreButton.alpha = 0.0
            self.commentBar.sendButton.alpha = 1.0
            self.commentBar.userImageView.alpha = 1.0
            self.commentBar.activityIndicator.alpha = 1.0
            self.commentBar.backgroundView.alpha = 1.0
            self.headerView.alpha = 0.0
            self.progressBar?.alpha = 0.0
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false
        //looping = false
        resume()
        delegate?.keyboardStateChange(keyboardUp)
        self.commentBar.likeButton.isUserInteractionEnabled = true
        self.commentBar.moreButton.isUserInteractionEnabled = true
        self.commentBar.sendButton.isUserInteractionEnabled = false
        self.commentsView.showTimeLabels(visible: false)
        
        if editCaptionMode {
            commentBar.textField.placeholder = "Comment"
            commentBar.textField.text = ""
            commentBar.sendButton.setTitle("Send", for: .normal)
            editCaptionMode = false
        }
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
            let height = self.frame.height
            let textViewFrame = self.commentBar.frame
            let textViewStart = height - textViewFrame.height
            self.commentBar.frame = CGRect(x: 0,y: textViewStart,width: textViewFrame.width, height: textViewFrame.height)
            
            self.commentsView.frame = CGRect(x: 0,y: self.getCommentsViewOriginY(),width: self.commentsView.frame.width,height: self.commentsView.frame.height)
            
            let infoFrame = self.infoView.frame
            let infoY = height - textViewFrame.height - infoFrame.height
            self.infoView.frame = CGRect(x: infoFrame.origin.x,y: infoY, width: infoFrame.width, height: infoFrame.height)
            
            self.commentBar.likeButton.alpha = 1.0
            self.commentBar.moreButton.alpha = 1.0
            self.commentBar.sendButton.alpha = 0.0
            self.commentBar.userImageView.alpha = 0.35
            self.commentBar.activityIndicator.alpha = 0.0
            self.commentBar.backgroundView.alpha = 0.0
            self.headerView.alpha = 1.0
            self.progressBar?.alpha = 1.0
        })
        
    }

    func getCommentsViewOriginY() -> CGFloat {
        return commentBar.frame.origin.y - infoView.frame.height - commentsView.frame.height
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fadeOutDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.headerView.alpha = 0
        })
    }
    
    func fadeInDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.headerView.alpha = 1
        })
    }
    
    func setDetailFade(_ alpha:CGFloat) {
        let multiple = alpha * alpha
        self.headerView.alpha = multiple
    }
    
    private(set) var inFocus = false
    func focus(_ inFocus:Bool) {
        if self.inFocus == inFocus { return }
        self.inFocus = inFocus
        if self.inFocus {
            self.headerView.isUserInteractionEnabled = false
            self.commentBar.isUserInteractionEnabled = false
            self.commentsView.isUserInteractionEnabled = false
            self.progressBar?.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.15, animations: {
                self.headerView.alpha = 0.0
                self.commentBar.alpha = 0.0
                self.commentsView.alpha = 0.0
                self.progressBar?.alpha = 0.0
            })
        } else {
            self.headerView.isUserInteractionEnabled = true
            self.commentBar.isUserInteractionEnabled = true
            self.commentsView.isUserInteractionEnabled = true
            self.progressBar?.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.15, animations: {
                self.headerView.alpha = 1.0
                self.commentBar.alpha = 1.0
                self.commentsView.alpha = 1.0
                self.progressBar?.alpha = 1.0
            })
        }
    }
    
    public lazy var content: UIImageView = {
        let view: UIImageView = UIImageView(frame: self.contentView.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public lazy var videoContent: UIView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        let frame = CGRect(x:0,y:0,width:width,height: height + 0)
        let view: UIImageView = UIImageView(frame: frame)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    
    public lazy var prevView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width * 0.45, height: self.bounds.height))
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        let dark = UIColor(white: 0.0, alpha: 0.5)
        gradient.colors = [dark.cgColor, UIColor.clear.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
        view.isUserInteractionEnabled = false
        view.alpha = 0.0
        return view
    }()
    
    lazy var headerView: PostHeaderView = {
        var view = UINib(nibName: "PostHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PostHeaderView
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        view.frame = CGRect(x: 0, y: 16, width: width, height: view.frame.height)
        return view
    }()
    
    lazy var commentsView: CommentsOverlayTableView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        var view = UINib(nibName: "CommentsOverlayTableView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentsOverlayTableView
        view.frame = CGRect(x: 0, y: height / 2, width: width, height: height * 0.36 )
        view.setup()
        return view
    }()
    
    lazy var infoView: StoryInfoView = {
        var view: StoryInfoView = UINib(nibName: "StoryInfoView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! StoryInfoView
        return view
    }()
    
    lazy var commentBar: CommentItemBar = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        var view: CommentItemBar = UINib(nibName: "CommentItemBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentItemBar
        view.frame = CGRect(x: 0, y: height - 50.0, width: width, height: 50.0)
        return view
    }()
    
    public lazy var gradientView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: self.bounds.height * 0.45, width: self.bounds.width, height: self.bounds.height * 0.55))
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        let dark = UIColor(white: 0.0, alpha: 0.35)
        gradient.colors = [UIColor.clear.cgColor , dark.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var guardView: UIView = {
        var view: UIView = UINib(nibName: "GuardView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
        view.frame = self.bounds
        return view
    }()

}

extension StoryViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 140 // Bool
    }
}

class TouchScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

