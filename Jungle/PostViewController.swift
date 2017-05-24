import UIKit
import AVFoundation
import Firebase

public class PostViewController: UICollectionViewCell, PostHeaderProtocol, ItemDelegate {
    
    var playerLayer:AVPlayerLayer?
    weak var delegate:PopupProtocol?
    var shouldAutoPause = true
    var animateInitiated = false
    var shouldAnimate = false
    var paused = false
    
    weak private(set) var storyItem:StoryItem!
    private(set) var cellIndex:Int?
    
    func preparePost(_ post:StoryItem, cellIndex: Int) {
        self.storyItem = post
        self.cellIndex = cellIndex
        self.content.image = nil
        self.destroyVideoPlayer()
        self.headerView.clean()
        self.footerView.clean()
        storyItem.delegate = self
        shouldAutoPause = true
        setItem()
    }
    
    deinit {
        print("Deinit >> PostViewController")
    }
    
    func showAuthor() {
        guard let item = self.storyItem else { return }
        delegate?.showUser(item.getAuthorId())
    }

    func handleFooterAction() {
        delegate?.showComments()
    }

    func animateIndicator() {

    }
    
    func stopIndicator() {

    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(headerView)
        contentView.addSubview(footerView)
        contentView.addSubview(captionView)
        
        headerView.snapTimer.isHidden = true
        headerView.snapTimer.removeFromSuperview()

        videoContent.isHidden = true
    }
    
    func itemDownloaded() {
        setItem()
    }
    
    func setItem() {
        guard let item = storyItem else { return }

        content.alpha = 1.0
        videoContent.alpha = 1.0
        
        if let image = storyItem.image {
            stopIndicator()
            self.content.image = image
        } else {
            NotificationCenter.default.removeObserver(self)
            animateIndicator()
            storyItem.download()
        }
        
        if item.contentType == .video {
            
            if let videoURL = UploadService.readVideoFromFile(withKey: item.getKey()) {
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
                animateIndicator()
                storyItem.download()
            }
        }

        self.headerView.setup(withUid: item.authorId, date: item.getDateCreated(), _delegate: self)
        
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
        
        if let locationKey = item.getLocationKey() {
            LocationService.sharedInstance.getLocationInfo(locationKey, completion: { location in
                self.headerView.setupLocation(location: location)
            })
        } else {
            self.headerView.setupLocation(location: nil)
        }
        
        UploadService.addView(post: item)
        footerView.setup(item)
        
        if let index = cellIndex {
            delegate?.newItem(index, item)
        }
        
    }
    
    func setForPlay(){
        
        if storyItem.needsDownload() {
            return
        }
        
        paused = false
        
        if storyItem.contentType == .image {
            videoContent.isHidden = true
            
        } else if storyItem.contentType == .video {
            videoContent.isHidden = false
            playVideo()
            loopVideo()
        }
        
        if shouldAutoPause {
            shouldAutoPause = false
            pause()
        }
        
    }
    
    func loopVideo() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            self.playerLayer?.player?.seek(to: kCMTimeZero)
            self.playerLayer?.player?.play()
        }
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
    
    func pause() {
        paused = true
        pauseVideo()
    }
    
    func resume() {
        paused = false
        guard let item = self.storyItem else { return }
        if item.contentType == .video {
            playVideo()
        }
    }
    
    func playVideo() {
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        pauseVideo()
    }
    
    func cleanUp() {
        content.image = nil
        destroyVideoPlayer()
        delegate = nil
        animateInitiated = false
        storyItem = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func reset() {
        shouldAutoPause = true
        pause()
    }
    
    func destroyVideoPlayer() {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer?.player = nil
        self.playerLayer = nil
        videoContent.isHidden = true
    }
    
    
    func tapped(gesture:UITapGestureRecognizer) {

    }
    
    func fadeInDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.footerView.alpha = 1
            self.headerView.alpha = 1
        })
    }
    
    func setDetailFade(_ alpha:CGFloat) {
        let multiple = alpha * alpha
        self.footerView.alpha = 0.75 * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple * multiple
        self.headerView.alpha = multiple
        self.captionView.textColor = UIColor(white: 1.0, alpha: 0.1 + 0.9 * alpha)
        self.captionView.alpha = 0.5 + 0.5 * alpha
    }

    func prepareForTransition(isPresenting:Bool) {
        
        if isPresenting {
            content.isHidden = false
            videoContent.isHidden = true
        } else {
            pause()
        }
    }


    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {
        let margin: CGFloat = 2.0
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIImageView = UIImageView(frame: frame)
        view.backgroundColor = UIColor.black
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public lazy var videoContent: UIView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        let frame = CGRect(x: 0,y: 0,width: width,height: height + 0)
        let view: UIImageView = UIImageView(frame: frame)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
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
