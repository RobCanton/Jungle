
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


public class StoryViewController: UICollectionViewCell, StoryProtocol, PostHeaderProtocol, UIScrollViewDelegate {

    private(set) var viewIndex = 0
    var returnIndex:Int?
    private(set) var cellIndex:Int?
    weak var story:Story!
    weak var item:StoryItem?
    weak var delegate:PopupProtocol?
    var activityView:NVActivityIndicatorView!
    
    var playerLayer:AVPlayerLayer?
    var currentProgress:Double = 0.0
    var timer:Timer?
    
    var totalTime:Double = 0.0
    
    var shouldAutoPause = true
    
    var flagLabel:UILabel?
    
    func addFlagLabel() {
       
    }
    
    deinit {
        print("Deinit >> StoryViewController")
    }
    
    func showAuthor() {
        guard let item = self.item else { return }
        delegate?.showUser(item.authorId)
    }
    
    func dismiss() {
        delegate?.dismissPopup(true)
    }
    
    func handleFooterAction() {
        delegate?.showComments()
    }
    
    func prepareStory(withLocation location:LocationStory, cellIndex: Int, atIndex index:Int?) {
        clearStoryView()
        shouldAutoPause = true
        self.cellIndex = cellIndex
        viewIndex = index ?? 0
        self.story = location
        self.story.delegate = self
        story.determineState()
    }
    
    func saveIndex() {
        returnIndex = viewIndex
    }
    
    func showComments() {
        
    }
    
    func prepareStory(withStory story:UserStory, cellIndex: Int,  atIndex index:Int?) {
        clearStoryView()
        shouldAutoPause = true
        self.cellIndex = cellIndex
        viewIndex = index ?? 0
        self.story = story
        self.story.delegate = self
        story.determineState()
    }
    
    func clearStoryView() {
        self.content.image = nil
        self.destroyVideoPlayer()
        self.headerView.clean()
        self.footerView.clean()
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
        if activityView.isAnimating {
            DispatchQueue.main.async {
                self.activityView.stopAnimating()
                self.animateInitiated = false
            }
        }
    }
    
    
    func contentLoaded() {
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

        if item.contentType == .image {
            prepareImageContent(item: item)
        } else if item.contentType == .video {
            prepareVideoContent(item: item)
        }
        
        self.headerView.setup(withUid: item.authorId, date: item.dateCreated, _delegate: self)
        
        if let locationKey = item.locationKey {
            LocationService.sharedInstance.getLocationInfo(locationKey, completion: { location in
                self.headerView.setupLocation(location: location)
            })
        } else {
            self.headerView.setupLocation(location: nil)
        }
        
        UploadService.addView(post: item)
        footerView.setup(item)
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
    
    var numCommentsRef: DatabaseReference?
    
    func prepareVideoContent(item:StoryItem) {
        /* CURRENTLY ASSUMING THAT IMAGE IS LOAD */
        if let image = item.image {
            content.image = image
            
        } else {
            return story.downloadStory()
        }
        createVideoPlayer()
        if let videoURL = UploadService.readVideoFromFile(withKey: item.key) {

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
        
        var itemLength = item.length
        if item.contentType == .image {
            videoContent.isHidden = true
            
        } else if item.contentType == .video {
            videoContent.isHidden = false
            playVideo()
            
            if let currentItem = playerLayer?.player?.currentTime() {
                itemLength -= currentItem.seconds
            }
        }
        headerView.startTimer(length: itemLength, index: viewIndex, total:story!.getPosts().count)
        timer = Timer.scheduledTimer(timeInterval: itemLength, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)

        if shouldAutoPause {
            shouldAutoPause = false
            pause()
        }
    }
    
    func nextItem() {
        guard let items = story.items else { return }
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
        delegate = nil
        animateInitiated = false
        item = nil
        returnIndex = nil
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func reset() {
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
    
    var paused = false
    var remainingTime:TimeInterval?
    
    func pause() {
        if paused { return }
        paused = true
        pauseVideo()
        headerView.pauseTimer()
        guard let timer = self.timer else { return }
        remainingTime = timer.fireDate.timeIntervalSinceNow
        timer.invalidate()
    }
    
    var looping = false

    
    func resume() {
        if !paused { return }
        paused = false
        guard let item = self.item else { return }
        if remainingTime != nil {
            timer = Timer.scheduledTimer(timeInterval: remainingTime!, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)
            remainingTime = nil
        } else {
            
        }
        if item.contentType == .video {
            playVideo()
        }
        
        headerView.resumeTimer()
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
            */
            pause()
        }
    }

    
    func tapped(gesture:UITapGestureRecognizer) {
        guard let _ = item else { return }
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

    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(prevView)
        contentView.addSubview(headerView)
        contentView.addSubview(footerView)
        contentView.addSubview(captionView)
        
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .ballScaleRipple, color: UIColor.black, padding: 1.0)
        activityView.center = contentView.center
        contentView.addSubview(activityView)
        
    }
    
    func fadeOutDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.footerView.alpha = 0
            self.headerView.alpha = 0
            self.captionView.textColor = UIColor(white: 1.0, alpha: 0)
            self.captionView.alpha = 0.65
        })
    }
    
    func fadeInDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.footerView.alpha = 1
            self.headerView.alpha = 1
            self.captionView.textColor = UIColor(white: 1.0, alpha: 1)
            self.captionView.alpha = 1
        })
    }
    
    func setDetailFade(_ alpha:CGFloat) {
        let multiple = alpha * alpha
        self.footerView.alpha = multiple
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

