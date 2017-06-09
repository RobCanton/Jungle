import UIKit
import AVFoundation
import Firebase
import NVActivityIndicatorView

public class PostViewController: UICollectionViewCell, PostHeaderProtocol, PostFooterProtocol, ItemDelegate, CommentItemBarProtocol, PostCaptionProtocol, CommentsTableProtocol {
    
    var playerLayer:AVPlayerLayer?
    weak var delegate:PopupProtocol?
    var shouldAutoPause = true
    var animateInitiated = false
    var shouldAnimate = false
    var paused = false
    
    var activityView:NVActivityIndicatorView!
    
    var keyboardUp = false
    var subscribedToPost = false
    
    var likedRef:DatabaseReference?
    var numLikesRef:DatabaseReference?
    var commentsRef:DatabaseReference?
    var subscribedRef:DatabaseReference?

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
        
        if let image = UploadService.readImageFromFile(withKey: storyItem.key) {

            if storyItem.contentType == .image {
                stopIndicator()
            }
            self.content.image = image
        }
        
        shouldAutoPause = true
        if storyItem.needsDownload() {
            storyItem.download()
        } else {
            setItem()
        }
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        print("Deinit >> PostViewController")
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
                self.setItem()
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
    
    func more() {
        delegate?.showMore()
    }
    
    var editCaptionMode = false
    func editCaption() {
        guard let item = self.storyItem else { return }
        editCaptionMode = true
        commentBar.textField.placeholder = "Edit Caption"
        commentBar.sendButton.setTitle("Set", for: .normal)
        commentBar.textField.becomeFirstResponder()
        commentBar.textField.text = item.caption
        //delegate?.editCaption()
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
        if !animateInitiated {
            animateInitiated = true
            DispatchQueue.main.async {
                if self.storyItem.needsDownload() {
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(content)
        contentView.addSubview(videoContent)
        contentView.addSubview(gradientView)
        contentView.addSubview(headerView)
        contentView.addSubview(footerView)
        contentView.addSubview(captionView)
        
        /* Info view */
        infoView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - infoView.frame.height,width: self.frame.width,height: infoView.frame.height)
        contentView.addSubview(infoView)
        
        contentView.addSubview(commentBar)
        
        /* Comments view */
        commentsView.frame = CGRect(x: 0,y: commentBar.frame.origin.y - commentsView.frame.height,width: commentsView.frame.width,height: commentsView.frame.height)
        contentView.addSubview(commentsView)
        
        headerView.snapTimer.isHidden = true
        headerView.snapTimer.removeFromSuperview()

        videoContent.isHidden = true
        
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .ballScaleRipple, color: UIColor.black, padding: 1.0)
        activityView.center = contentView.center
        contentView.addSubview(activityView)
    }
    
    func itemDownloaded() {
        setItem()
    }
    
    func setItem() {
        guard let item = storyItem else { return }
        
        self.content.image = nil
        commentBar.setup(item.authorId == mainStore.state.userState.uid)
        
        if let image = UploadService.readImageFromFile(withKey: item.key) {
            
            print("IMAGE SET")
            if item.contentType == .image {
                stopIndicator()
            }
            self.content.image = image
        } else {
            animateIndicator()
            storyItem.download()
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
                animateIndicator()
                storyItem.download()
            }
        }

        self.headerView.setup(withUid: item.authorId, date: item.dateCreated, _delegate: self)
        self.headerView.setNumLikes(item.numLikes)
        self.headerView.setNumComments(item.numComments)
        
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
        self.infoView.setInfo(withUid: item.authorId, item: item, delegate: self)
        
        
        self.headerView.setupLocation(locationKey: item.locationKey)
        
        UploadService.addView(post: item)
        footerView.setup(item)
        footerView.delegate = self
        
        let uid = mainStore.state.userState.uid
        likedRef?.removeAllObservers()
        likedRef = Database.database().reference().child("uploads/likes/\(item.key)/\(uid)")
        likedRef!.observe(.value, with: { snapshot in

            self.commentBar.setLikedStatus(snapshot.exists(), animated: false)
        })
        
        numLikesRef?.removeAllObservers()
        numLikesRef = Database.database().reference().child("uploads/meta/\(item.key)/likes")
        numLikesRef!.observe(.value, with: { snapshot in
            var count = 0
            if let _count = snapshot.value as? Int {
                count = _count
            }
            self.headerView.setNumLikes(count)
            item.numLikes = count
            
        })
        
        commentsView.setTableComments(comments: item.comments, animated: false)
        commentsRef?.removeAllObservers()
        commentsRef = UserService.ref.child("uploads/comments/\(item.key)")
        
        if let lastItem = item.comments.last {
            let lastKey = lastItem.key
            let ts = lastItem.date.timeIntervalSince1970 * 1000
            commentsRef?.queryOrdered(byChild: "timestamp").queryStarting(atValue: ts).observe(.childAdded, with: { snapshot in
                
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                if key != lastKey {
                    let author = dict["author"] as! String
                    let text = dict["text"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                    item.addComment(comment)
                    self.headerView.setNumComments(item.numComments)
                    self.commentsView.setTableComments(comments: item.comments, animated: true)
                }
            })
        } else {
            commentsRef?.observe(.childAdded, with: { snapshot in
                let dict = snapshot.value as! [String:Any]
                let key = snapshot.key
                let author = dict["author"] as! String
                let text = dict["text"] as! String
                let timestamp = dict["timestamp"] as! Double
                let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                item.addComment(comment)
                self.headerView.setNumComments(item.numComments)
                self.commentsView.setTableComments(comments: item.comments, animated: true)
            })
        }
        commentBar.textField.delegate = self
        commentBar.delegate = self
        
        subscribedToPost = false
        subscribedRef?.removeAllObservers()
        subscribedRef = UserService.ref.child("uploads/subscribers/\(item.key)/\(uid)")
        subscribedRef?.observe(.value, with: { snapshot in
            self.subscribedToPost = snapshot.exists()
        })
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
            //loopVideo()
            //timer = Timer.scheduledTimer(timeInterval: storyItem.length, target: self, selector: #selector(setItem), userInfo: nil, repeats: false)
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
        self.footerView.alpha = multiple
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
    
    lazy var commentsView: CommentsOverlayTableView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
        var view = UINib(nibName: "CommentsOverlayTableView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CommentsOverlayTableView
        view.frame = CGRect(x: 0, y: height / 2, width: width, height: height * 0.36 )
        view.setup()
        return view
    }()
    
    lazy var infoView: StoryInfoView = {
        let width: CGFloat = (UIScreen.main.bounds.size.width)
        let height: CGFloat = (UIScreen.main.bounds.size.height)
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
