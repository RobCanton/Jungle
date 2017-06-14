import UIKit
import AVFoundation
import Firebase
import NVActivityIndicatorView

public class PostViewController: UICollectionViewCell, PostHeaderProtocol, PostFooterProtocol, ItemDelegate, ItemStateProtocol, CommentItemBarProtocol, PostCaptionProtocol, CommentsTableProtocol {
    
    var playerLayer:AVPlayerLayer?
    weak var delegate:PopupProtocol?
    var shouldAutoPause = true
    var shouldAnimate = false
    var paused = false
    
    var activityView:NVActivityIndicatorView!
    
    var editCaptionMode = false
    var keyboardUp = false
    var subscribedToPost = false
    
    var itemStateController:ItemStateController!

    weak private(set) var storyItem:StoryItem!
    private(set) var cellIndex:Int?
    
    deinit { print("Deinit >> PostViewController") }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(gradientView)
        contentView.addSubview(headerView)
        
        /* Info view */
        infoView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - infoView.frame.height,width: self.frame.width,height: 0)
        contentView.addSubview(infoView)
        
        contentView.addSubview(commentBar)
        
        /* Comments view */
        commentsView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - commentsView.frame.height,width: commentsView.frame.width,height: commentsView.frame.height)
        contentView.addSubview(commentsView)
        
        videoContent.isHidden = true
        
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), type: .ballBeat, color: UIColor.white, padding: 1.0)
        activityView.center = contentView.center
        contentView.addSubview(activityView)
        
        /* Item State Controller */
        itemStateController = ItemStateController()
    }
    
    func preparePost(_ post:StoryItem, cellIndex: Int) {
        storyItem = post
        self.cellIndex = cellIndex
        content.image = nil
        destroyVideoPlayer()
        headerView.clean()
        videoContent.isHidden = true
        storyItem.delegate = self
        
        content.image = UploadService.readImageFromFile(withKey: post.key)

        itemStateController.removeAllObservers()
        itemStateController.delegate = self
        itemStateController.setupItem(post)
        
        setOverlays()
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setOverlays() {
        guard let item = storyItem else { return }
        
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
        
        //commentsView.setTableComments(comments: item.comments, animated: false)
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
    
    func itemStateDidChange(comments: [Comment]) {
        print("Num comments changed: \(comments.count)")
        self.headerView.setNumComments(comments.count)
        self.commentsView.setTableComments(comments: comments, animated: true)
    }
    
    func itemStateDidChange(subscribed: Bool) {
        self.subscribedToPost = subscribed
        
    }
    
    func itemDownloading() {
        animateIndicator()
    }
    
    func itemDownloaded() {
        guard let item = storyItem else { return }
        if let image = UploadService.readImageFromFile(withKey: item.key) {
            
            if item.contentType == .image {
                stopIndicator()
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
    func setForPlay(){
        
        paused = false
        
        if storyItem.contentType == .video {
            videoContent.isHidden = false
            playVideo()
        }
        
        if shouldAutoPause {
            shouldAutoPause = false
            pause()
        }
        
    }
    
    func sendComment(_ comment: String) {
        
        guard let item = self.storyItem else { return }
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
        guard let item = self.storyItem else { return }
        
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
        guard let item = self.storyItem else { return }
        editCaptionMode = true
        commentBar.textField.placeholder = "Edit Caption"
        commentBar.sendButton.setTitle("Set", for: .normal)
        commentBar.textField.becomeFirstResponder()
        commentBar.textField.text = item.caption
    }
    
    func showAuthor() {
        guard let item = self.storyItem else { return }
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

    func handleFooterAction() {
        delegate?.showComments()
    }
    
    func showComments() {
        delegate?.showComments()
    }
    
    func liked(_ liked:Bool) {
        guard let item = self.storyItem else { return }
        if liked {
            UploadService.addLike(post: item)
        } else {
            UploadService.removeLike(post: item)
        }
    }

    func animateIndicator() {
        self.content.alpha = 0.6
        
        self.activityView.startAnimating()
    }
    
    func stopIndicator() {
        self.content.alpha = 1.0
        self.activityView.stopAnimating()
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
        //itemStateController.delegate = nil
        paused = true
        pauseVideo()
    }
    
    func resume() {
        //itemStateController.delegate = self
        activityView.alpha = 1.0
        paused = false
        guard let item = self.storyItem else { return }
        
        
        if item.needsDownload() {
            itemStateController.download()
        } else if item.contentType == .video {
            if playerLayer == nil {
                shouldAutoPause = false
                itemDownloaded()
            } else {
                playVideo()
            }
        }
    }
    
    func playVideo() {
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func replayVideo() {
        self.playerLayer?.player?.seek(to: kCMTimeZero)
        self.playerLayer?.player?.play()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seek(to: CMTimeMake(0, 1))
        pauseVideo()
    }
    
    func cleanUp() {
        content.image = nil
        destroyVideoPlayer()
        delegate = nil
        storyItem = nil
        
        headerView.delegate = nil
        infoView.delegate = nil
        commentBar.delegate = nil
        //itemStateController.removeAllObservers()
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
    
    func fadeInDetails() {
        UIView.animate(withDuration: 0.15, animations: {
            self.headerView.alpha = 1
        })
    }
    
    func setDetailFade(_ alpha:CGFloat) {
        let multiple = alpha * alpha
        self.headerView.alpha = multiple
    }

    func prepareForTransition(isPresenting:Bool) {
        activityView.alpha = 0.0
        if isPresenting {
            content.isHidden = false
            videoContent.isHidden = true
        } else {
            pause()
        }
    }
    func keyboardWillAppear(notification: NSNotification){
        keyboardUp = true
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
            self.commentBar.activityIndicator.alpha = 1.0
            self.commentBar.backgroundView.alpha = 1.0
            self.headerView.alpha = 0.0
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false
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
            self.commentBar.activityIndicator.alpha = 0.0
            self.commentBar.backgroundView.alpha = 0.0
            self.headerView.alpha = 1.0
        })
        
    }
    
    func getCommentsViewOriginY() -> CGFloat {
        return commentBar.frame.origin.y - infoView.frame.height - commentsView.frame.height
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
        view.frame = CGRect(x: 0, y: 0, width: width, height: view.frame.height/2)
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

}

extension PostViewController: UITextFieldDelegate {
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
