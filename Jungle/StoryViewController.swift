
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


public class StoryViewController: UICollectionViewCell, StoryProtocol, UIScrollViewDelegate {

    var viewIndex = 0
    var returnIndex:Int?
    var item:StoryItem?
    var delegate:PopupProtocol?
    var activityView:NVActivityIndicatorView!
    
    var footerTapped:UITapGestureRecognizer!
    
    var playerLayer:AVPlayerLayer?
    var currentProgress:Double = 0.0
    var timer:Timer?
    
    var totalTime:Double = 0.0
    
    var progressBar:StoryProgressIndicator?
    var story:Story!
    
    var shouldAutoPause = true
    
    var flagLabel:UILabel?
    
    func addFlagLabel() {
       
        
    
    }
    
    func showAuthor() {
        guard let item = self.item else { return }
        delegate?.showUser(item.getAuthorId())
    }
    
    func handleFooterAction() {
        delegate?.showComments()
    }
    
    func prepareStory(withLocation location:LocationStory) {
        shouldAutoPause = true
        self.story = location
        self.story.delegate = self
        story.determineState()
        
    }
    
    func prepareStory(withStory story:UserStory) {
        shouldAutoPause = true
        self.story = story
        self.story.delegate = self
        story.determineState()
    }
    
    func observeKeyboard() {
        
    }
    
    func removeObserver() {
        
    }
    
    func stateChange(_ state:UserStoryState) {
        switch state {
        case .notLoaded:
            story.downloadItems()
            animateIndicator()
            break
        case .loadingItemInfo:
            animateIndicator()
            break
        case .itemInfoLoaded:
            animateIndicator()
            story.downloadStory()
            break
        case .loadingContent:
            animateIndicator()
            break
        case .contentLoaded:
            stopIndicator()
            contentLoaded()
            break
        }
    }
    var animateInitiated = false
    
    func animateIndicator() {
        if !animateInitiated {
            animateInitiated = true
            DispatchQueue.main.async {
                if self.story.state != .contentLoaded {
                    self.activityView.startAnimating()
                }
            }
        }
    }
    
    func stopIndicator() {
        if activityView.animating {
            DispatchQueue.main.async {
                self.activityView.stopAnimating()
                self.animateInitiated = false
            }
        }
    }
    
    
    func contentLoaded() {

        let screenWidth: CGFloat = (UIScreen.main.bounds.size.width)
        let screenHeight: CGFloat = (UIScreen.main.bounds.size.height)
        let margin:CGFloat = 12.0
        //progressBar?.removeFromSuperview()
        //progressBar = StoryProgressIndicator(frame: CGRect(x: margin,y: margin, width: screenWidth - margin * 2,height: 1.5))
        //progressBar!.createProgressIndicator(_story: story)
        //contentView.addSubview(progressBar!)
        
        if returnIndex != nil {
            viewIndex = returnIndex!
            returnIndex = nil
        } else {
            viewIndex = 0
    
            for item in story.items! {

                totalTime += item.getLength()
            }
            
            if viewIndex >= story.items!.count{
                viewIndex = 0
            }
            
            if viewIndex > 0 {
                viewIndex -= 1
            }
        }
        self.setupItem()
    }
    
    func setupItem() {
        
        killTimer()
        pauseVideo()

        guard let items = story.items else { return }
        if viewIndex >= items.count { return }
        
        let item = items[viewIndex]
        self.item = item

        if item.contentType == .image {
            prepareImageContent(item: item)
        } else if item.contentType == .video {
            prepareVideoContent(item: item)
        }
        
        UserService.getUser(item.authorId, completion: { user in
            if user != nil {
                
                self.headerView.setup(withUser: user!, date: item.getDateCreated(), optionsHandler: self.delegate?.showOptions)
                self.headerView.showAuthorHandler = self.showAuthor
                
                if let caption = item.getCaption(), let captionPos = item.getCaptionPos() {
                    self.captionView.text = caption
                    self.captionView.fitHeightToContent()
                    self.captionView.center = CGPoint(x: self.frame.width / 2, y: self.frame.height * captionPos)
                    self.captionView.isHidden = false
                } else {
                    self.captionView.isHidden = true
                    self.captionView.text = ""
                    self.captionView.fitHeightToContent()
                    self.captionView.center = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
                }
            }
        })
        
        if let locationKey = item.getLocationKey() {
            LocationService.sharedInstance.getLocationInfo(locationKey, completion: { location in
                if location != nil {
                    self.headerView.setupLocation(location: location!)
                }
            })
        }
        
        UploadService.addView(post: item)
        footerView.setCommentsLabelToCount(item.getNumComments())
        
        numCommentsRef?.removeAllObservers()
        numCommentsRef = FIRDatabase.database().reference().child("uploads/meta/\(item.getKey())/comments")
        numCommentsRef!.observe(.value, with: { snapshot in
            var numComments = 0
            if snapshot.exists() {
                if let _numComments = snapshot.value as? Int {
                    numComments = _numComments
                }
            }
            item.updateNumComments(numComments)
            self.footerView.setCommentsLabelToCount(item.getNumComments())
        })
        
        delegate?.newItem(item)
    }
    
    func prepareImageContent(item:StoryItem) {
        
        if let image = item.image {
            content.image = image
            self.playerLayer?.player?.replaceCurrentItem(with: nil)
            self.setForPlay()
        } else {
            story.downloadStory()
        }
    }
    
    var numCommentsRef: FIRDatabaseReference?
    
    func prepareVideoContent(item:StoryItem) {
        /* CURRENTLY ASSUMING THAT IMAGE IS LOAD */
        if let image = item.image {
            content.image = image
            
        } else {
            return story.downloadStory()
        }
        createVideoPlayer()
        if let videoURL = UploadService.readVideoFromFile(withKey: item.getKey()) {

            let asset = AVAsset(url: videoURL)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                DispatchQueue.main.async {
                    let item = AVPlayerItem(asset: asset)
                    self.playerLayer?.player?.replaceCurrentItem(with: item)
                    self.setForPlay()
                }
            })
        } else {
            story.downloadStory()
        }
    }
    
    func setForPlay() {
        if story.state != .contentLoaded {
            return
        }
        
        guard let item = self.item else {
            return }
        
        paused = false
        
        var itemLength = item.getLength()
        if item.contentType == .image {
            videoContent.isHidden = true
            
        } else if item.contentType == .video {
            videoContent.isHidden = false
            playVideo()
            
            if let currentItem = playerLayer?.player?.currentTime() {
                itemLength -= currentItem.seconds
            }
        }

        //progressBar?.activateIndicator(itemIndex: viewIndex)
        headerView.startTimer(length: itemLength, index: viewIndex, total:story!.getPosts().count)
        timer = Timer.scheduledTimer(timeInterval: itemLength, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)

        if shouldAutoPause {
            shouldAutoPause = false
            pause()
        }
    }
    
    func nextItem() {
        guard let items = story.items else { return }
        viewIndex += 1
        
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
        let diff = remaining / item.getLength()
        
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
        content.image = nil
        destroyVideoPlayer()
        killTimer()
        //progressBar?.resetAllProgressBars()
        //progressBar?.removeFromSuperview()
        delegate = nil
        animateInitiated = false
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func reset() {
        killTimer()
        //progressBar?.resetActiveIndicator()
        pauseVideo()
    }
    
    var blockInappropriateContent = true
    
    func playVideo() {
        guard let item = self.item else { return }

        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        pauseVideo()
    }
    
    var paused = false
    var remainingTime:TimeInterval?
    
    func pause() {
        if paused { return }
        paused = true
        pauseVideo()
        //progressBar?.pauseActiveIndicator()
        headerView.pauseTimer()
        guard let timer = self.timer else { return }
        remainingTime = timer.fireDate.timeIntervalSinceNow
        timer.invalidate()
    }
    
    func resume() {
        if !paused { return }
        paused = false
        guard let item = self.item else { return }
        print("RESUME ITEM: \(item.getKey())")
        if remainingTime != nil {
            //timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: remainingTime!, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)
            remainingTime = nil
        } else {
            
        }
        if item.contentType == .video {
            playVideo()
        }
        
        headerView.resumeTimer()
        //progressBar?.resumeActiveIndicator()
    }
    
    func focusItem() {
        UIView.animate(withDuration: 0.15, animations: {
            //self.progressBar?.alpha = 0.0
        })
    }
    
    func unfocusItem() {
        UIView.animate(withDuration: 0.2, animations: {
            //self.progressBar?.alpha = 1.0
        })
    }
    
    
    func killTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func prepareForTransition(isPresenting:Bool) {
        
        if isPresenting {
            content.isHidden = false
            videoContent.isHidden = true
        } else {
            //story.delegate = nil
            /*killTimer()
            resetVideo()
            progressBar?.resetActiveIndicator()
            */
            pause()
        }
    }

    
    func tapped(gesture:UITapGestureRecognizer) {
        guard let _ = item else { return }
        if keyboardUp {
            
        } else {
            let tappedPoint = gesture.location(in: self)
            let width = self.bounds.width
            if tappedPoint.x < width * 0.25 {
                prevItem()
                prevView.alpha = 1.0
                UIView.animate(withDuration: 0.25, animations: {
                    self.prevView.alpha = 0.0
                })
            } else {
                nextItem()
            }
        }
    }

    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    var keyboardUp = false
    
    var scrollView:UIScrollView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(gradientView)
        contentView.addSubview(prevView)
        contentView.addSubview(headerView)
        contentView.addSubview(footerView)
        contentView.addSubview(captionView)
        
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .ballScaleRipple, color: UIColor.white, padding: 1.0)
        activityView.center = contentView.center
        contentView.addSubview(activityView)
        
        let screenBounds = UIScreen.main.bounds
        scrollView = UIScrollView(frame: screenBounds)
        
        //contentView.addSubview(scrollView)
        
        let v1 = UIView(frame: screenBounds)
        v1.backgroundColor = UIColor.clear
        
        let v2 = UIView(frame: screenBounds)
        v2.backgroundColor = UIColor.blue
        
        var v2Frame = v2.frame
        v2Frame.origin.y = screenBounds.height
        v2.frame = v2Frame
        
        scrollView.addSubview(v1)
        scrollView.addSubview(v2)
        scrollView.contentSize = CGSize(width: screenBounds.width, height: screenBounds.height * 2.0)
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        
        footerView.pullUpTapHandler = handleFooterAction
        
        
    }
    
    var commentsActive = false
    
    func fadeOutDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.footerView.alpha = 0
            //self.progressBar?.alpha = 0
            self.headerView.alpha = 0
            self.captionView.textColor = UIColor(white: 1.0, alpha: 0)
            self.captionView.alpha = 0.65
        })
    }
    
    func fadeInDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.footerView.alpha = 1
            //self.progressBar?.alpha = 1
            self.headerView.alpha = 1
            self.captionView.textColor = UIColor(white: 1.0, alpha: 1)
            self.captionView.alpha = 1
        })
    }
    
    func setDetailFade(_ alpha:CGFloat) {
        let multiple = alpha * alpha
        self.footerView.alpha = 0.75 * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple
        //self.progressBar?.alpha = multiple
        self.headerView.alpha = multiple
        self.captionView.textColor = UIColor(white: 1.0, alpha: 0.1 + 0.9 * alpha)
        self.captionView.alpha = 0.5 + 0.5 * alpha
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
    
    public lazy var gradientView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: self.bounds.height * 0.8, width: self.bounds.width, height: self.bounds.height * 0.20))
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        let dark = UIColor(white: 0.0, alpha: 0.7)
        gradient.colors = [UIColor.clear.cgColor , dark.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    public lazy var prevView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width * 0.4, height: self.bounds.height))
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        let dark = UIColor(white: 0.0, alpha: 0.42)
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
        view.frame = CGRect(x: 0, y: 0, width: width, height: view.frame.height)
        return view
    }()
    
    lazy var footerView: PostFooterView = {
        let margin:CGFloat = 0.0
        var view = UINib(nibName: "PostFooterView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PostFooterView
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        view.frame = CGRect(x: margin, y: height - view.frame.height, width: width, height: view.frame.height)
        return view
    }()
    
    fileprivate lazy var captionView: UITextView = {
        let definiteBounds = UIScreen.main.bounds
        let captionView = UITextView(frame: CGRect(x: 0,y: 0,width: definiteBounds.width,height: 44))
        captionView.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        captionView.textColor = UIColor.white
        captionView.textAlignment = .center
        captionView.backgroundColor = UIColor(white: 0.0, alpha: 0.65)
        captionView.isScrollEnabled = false
        captionView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        captionView.isUserInteractionEnabled = false
        captionView.isHidden = true
        captionView.text = "test"
        captionView.fitHeightToContent()
        captionView.text = ""
        captionView.center = CGPoint(x: definiteBounds.width / 2, y: definiteBounds.height / 2)
        return captionView
    }()
    
    
}

class TouchScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

