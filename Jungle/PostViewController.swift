import UIKit
import AVFoundation
import Firebase

public class PostViewController: UICollectionViewCell, ItemDelegate {
    
    
    var tap:UITapGestureRecognizer!
    var playerLayer:AVPlayerLayer?
    
    var commentsRef:FIRDatabaseReference?
    
    var keyboardUp = false
    
    var delegate:PopupProtocol?
    
    func showOptions() {
        pauseVideo()
        delegate?.showOptions()
    }
    
    var shouldPlay = false

    
    
    var storyItem:StoryItem! {
        didSet {
            storyItem.delegate = self
            shouldPlay = false
            setItem()
        }
    }

    
    func showViewers() {

    }
    
    func handleFooterAction(_ like: Bool?) {
        guard let item = self.storyItem else { return }
        if let like = like {
            if like {
                UploadService.addLike(post: item)
                item.addLike(mainStore.state.userState.uid)
            } else {
                UploadService.removeLike(postKey: item.getKey())
                item.removeLike(mainStore.state.userState.uid)
            }
        } else {
            delegate?.showDeleteOptions()
        }
        
        
        
        //headerView.setLikes(post: item)
    }
    
    func more() {
        delegate?.showOptions()
    }
    
    func sendComment(_ comment: String) {
        guard let item = self.storyItem else { return }
        UploadService.addComment(post: item, comment: comment)
    }
    
    func toggleLike(_ like: Bool) {

    }
    var animateInitiated = false
    
    var shouldAnimate = false
    func animateIndicator() {

    }
    
    func stopIndicator() {

    }
    
        var footerTapped:UITapGestureRecognizer!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(gradientView)
        contentView.addSubview(headerView)
        contentView.addSubview(footerView)

        videoContent.isHidden = true
        
        footerTapped = UITapGestureRecognizer(target: self, action: #selector(handleFooterTap))
        footerView.isUserInteractionEnabled = true
        footerView.addGestureRecognizer(footerTapped)
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
                        
                        if self.shouldPlay {
                            self.setForPlay()
                        }
                    }
                })
            } else {
                animateIndicator()
                storyItem.download()
            }
        }
        
        UserService.getUser(item.authorId, completion: { user in
            if user != nil {
                let caption = "\(user!.getUsername()) \(item.caption)"
                let width = self.frame.width - (42 + 50)
                var size:CGFloat = 8.0 + 25 + 2
                
                size +=  UILabel.size(withUsername: user!.getUsername(), andCaption: item.caption, forWidth: width).height + 8
                
                self.footerView.frame = CGRect(x: 0, y: self.frame.height - size, width: self.frame.width, height: size)
                self.footerView.setInfo( item: item, user: user!, actionHandler: self.handleFooterAction)
            }
        })
        
        //headerView.setup(withPlaceId: item.getLocationKey(), optionsHandler: delegate?.showOptions)
        
    
    }
    
    
    func itemDownloaded() {
        //activityView?.stopAnimating()
        setItem()
    }
    
    
    
    func setForPlay(){
        
        if storyItem.needsDownload() {
            shouldPlay = true
            return
        }
        
        shouldPlay = false
        
        if storyItem.contentType == .image {
            videoContent.isHidden = true
            
        } else if storyItem.contentType == .video {
            videoContent.isHidden = false
            playVideo()
            loopVideo()
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
    
    func playVideo() {
        guard let item = self.storyItem else { return }
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        pauseVideo()
    }
    
    func prepareForTransition(isPresenting:Bool) {
        content.isHidden = false
        videoContent.isHidden = true
    }
    
    func cleanUp() {
        content.image = nil
        destroyVideoPlayer()
    }
    
    func reset() {
        content.isHidden = false
        videoContent.isHidden = true
        resetVideo()
    }
    
    func destroyVideoPlayer() {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer?.player = nil
        self.playerLayer = nil
        videoContent.isHidden = true
    }
    
    func enableTap() {
        self.addGestureRecognizer(tap)
    }
    
    func disableTap() {
        self.removeGestureRecognizer(tap)
    }
    
    func tapped(gesture:UITapGestureRecognizer) {

    }
    

    func focusItem() {

    }
    
    func unfocusItem() {
    }
    
    
    var commentsActive = false
    func handleFooterTap(sender: UITapGestureRecognizer) {
        delegate?.showComments()
        commentsActive = true
        UIView.animate(withDuration: 0.15, animations: {
            self.footerView.alpha = 0
            self.headerView.alpha = 0
        })
        // scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.frame.height), animated: true)
    }
    
    func fadeInDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.footerView.alpha = 1
            self.headerView.alpha = 1
        })
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
    
    lazy var headerView: PostHeaderView = {
        let margin:CGFloat = 2.0
        var view = UINib(nibName: "PostHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PostHeaderView
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        view.frame = CGRect(x: margin, y: margin + 4.0, width: width, height: view.frame.height)
        return view
    }()
    
    lazy var footerView: StoryDetailsView = {
        let margin:CGFloat = 2.0
        var view = UINib(nibName: "StoryDetailsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! StoryDetailsView
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        view.frame = CGRect(x: margin, y: height - view.frame.height, width: width, height: view.frame.height)
        return view
    }()

}

extension PostViewController: UITextFieldDelegate {
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
