//
//  ChatViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import ReSwift
import Firebase
import View2ViewTransition
import Alamofire


class ChatViewController: JSQMessagesViewController, GetUserProtocol {
    
    var popUpMode = false
    var refreshControl: UIRefreshControl!

    //var containerDelegate:ContainerViewController?
    let incomingBubble = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero).incomingMessagesBubbleImage(with: UIColor(white: 0.90, alpha: 1.0))
    let incomingBubbleWithTail = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor(white: 0.90, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero).outgoingMessagesBubbleImage(with: accentColor)
    let outgoingBubbleWithTail = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: accentColor)
    
    var messages:[JSQMessage]!
    
    var settingUp = true
    
    var conversationKey:String!
    var partner:User!
    var partnerImage:UIImage?
    

    func userLoaded(user: User) {
        partner = user
       
    }
    
    let transitionController: TransitionController = TransitionController()

    var activityIndicator:UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        
        if !popUpMode {
            self.addNavigationBarBlurBackdrop()
        }
        
        messages = [JSQMessage]()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(accentColor, for: .normal)
        self.inputToolbar.contentView.leftBarButtonItemWidth = 0
        self.inputToolbar.contentView.textView.placeHolder = "New message"
        if let user = userState.user {
            self.inputToolbar.contentView.textView.placeHolder = "New message as @\(user.username)"
        }
        
        //collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 32, height: 32)
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        collectionView?.collectionViewLayout.springinessEnabled = true
        collectionView?.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x:0,y:0,width:50,height:50))
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.center = CGPoint(x:UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2 - 50)
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    
        conversationKey = createUserIdPairKey(uid1: mainStore.state.userState.uid, uid2: partner.uid)
        title = partner.username
        
        downloadRef = UserService.ref.child("directMessages/\(conversationKey!)/messages")
        
        downloadRef?.queryOrderedByKey().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists() {
                self.stopActivityIndicator()
            }
            self.downloadMessages()
        }, withCancel: { error in
            self.stopActivityIndicator()
            self.downloadMessages()
        })
        self.setup()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name:NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        let optionsButton = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(showUserOptions))
        optionsButton.tintColor = UIColor.black
        navigationItem.rightBarButtonItem = optionsButton

    }
    
    
    
    func handleClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showUserOptions() {

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { _ in
            let reportSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            reportSheet.addAction(UIAlertAction(title: "Inappropriate Message(s)", style: .destructive, handler: { success in
                UserService.reportUser(user: self.partner, type: .InappropriateMessages, completion: { success in
                    
                })
            }))
            
            reportSheet.addAction(UIAlertAction(title: "Spam", style: .destructive, handler: { _ in
                UserService.reportUser(user: self.partner, type: .SpamMessages, completion: { success in
                    
                })
            }))
            
            reportSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(reportSheet, animated: true, completion: nil)
            
            
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    
    
    func startActivityIndicator() {
        DispatchQueue.main.async {
            if self.settingUp {
               self.activityIndicator.startAnimating()
            }
        }
    }
    
    
    func stopActivityIndicator() {
        if settingUp {
            settingUp = false
            print("Switch activity indicator")
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.refreshControl = UIRefreshControl()
                self.refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
                self.collectionView?.addSubview(self.refreshControl)

            }
        }
    }
    
    func handleRefresh() {
        let oldestLoadedMessage = messages[0]
        let date = oldestLoadedMessage.date!
        let endTimestamp = date.timeIntervalSince1970 * 1000
        
        limit += 16
        downloadRef?.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit).queryEnding(atValue: endTimestamp).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var messageBatch = [JSQMessage]()
                _ = snapshot.value as! [String:AnyObject]
                
                for message in snapshot.children {
                    let messageSnap = message as! DataSnapshot
                    let dict = messageSnap.value as! [String: AnyObject]
                    
                    let senderId  = dict["sender"] as! String
                    let timestamp = dict["timestamp"] as! Double
                    
                    if timestamp != endTimestamp {
                        let date = NSDate(timeIntervalSince1970: timestamp/1000)
                        
                        if let uploadKey = dict["uploadKey"] as? String, let uploadURL = dict["uploadURL"] as? String {
                            let mediaItem = AsyncPhotoMediaItem(key: uploadKey, withURL: uploadURL)
                            let mediaMessage = JSQMessage(senderId: senderId, senderDisplayName: "", date: date as Date!, media: mediaItem)
                            messageBatch.append(mediaMessage!)
                            
                        } else if let text = dict["text"] as? String {
                            let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date as Date!, text: text)
                            //self.messages.append(message!)
                            messageBatch.append(message!)
                        }
                    }

                }

                if messageBatch.count > 0 {
                    self.messages.insert(contentsOf: messageBatch, at: 0)
                    self.reloadMessagesView()
                    self.refreshControl.endRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                    self.refreshControl.isEnabled = false
                    self.refreshControl.removeFromSuperview()
                }
            } else {
                self.refreshControl.endRefreshing()
                self.refreshControl.isEnabled = false
                self.refreshControl.removeFromSuperview()
            }
        })
    }
    
    func appMovedToBackground() {
        //downloadRef?.removeAllObservers()
        //conversation.listenToConversation()
    }
    
    func appWillEnterForeground() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        downloadRef?.removeAllObservers()
        
        self.navigationController?.view.backgroundColor = UIColor.clear
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.navigationController?.delegate === transitionController {
            self.navigationController?.delegate = nil
        }
        //self.navigationController?.navigationBar.isUserInteractionEnabled = true
        
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
        //set seen timestamp
        if messages.count > 0 {
            let ref = UserService.ref.child("users/directMessages/\(userState.uid)/\(partner.uid)/seen")
            ref.setValue(true)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            if indexPath.row < messages.count - 1 {
                
                
                let nextMessage = messages[indexPath.row + 1]
                
                let gap = nextMessage.date.timeIntervalSince(data.date)
                if gap > 1800 {
                    return self.outgoingBubbleWithTail
                    
                }
                
                if nextMessage.senderId == self.senderId {
                    return self.outgoingBubble
                }
                
                
            }
            return self.outgoingBubbleWithTail
        default:
            
            if indexPath.row < messages.count - 1 {
                
                
                let nextMessage = messages[indexPath.row + 1]
                
                let gap = nextMessage.date.timeIntervalSince(data.date)
                if gap > 1800 {
                    return self.incomingBubbleWithTail
                    
                }
                
                if nextMessage.senderId != self.senderId {
                    return self.incomingBubble
                }
                
                
            }
            
            return self.incomingBubbleWithTail
        }
    }
    

    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let data = messages[indexPath.row]
        print("didTapMessageBubbleAt!")
        if data.isMediaMessage {
            print("isMediaMessage")
            if let media = data.media as? AsyncPhotoMediaItem {
                print("AsyncPhotoMediaItem")
                if let item = media.item {
                    print("ITEM TING!")
                    presentPost(post:item, indexPath: indexPath)
                }
            }
            //globalMainInterfaceProtocol?.presentChatPost(chatController: self, post: data.media, initialIndexPath: <#T##IndexPath#>)
        }
    }
    
    func presentPost(post: StoryItem, indexPath:IndexPath) {
        guard let nav = self.navigationController else { return }
        let galleryViewController: GalleryViewController = GalleryViewController()
        galleryViewController.showCommentsOnAppear = true
        galleryViewController.isSingleItem = true
        galleryViewController.posts = [post]
        galleryViewController.transitionController = self.transitionController
        
        self.transitionController.userInfo = ["destinationIndexPath": IndexPath(item: 0, section: 0) as AnyObject, "initialIndexPath": indexPath as AnyObject]
        transitionController.cornerRadius = 6.0
        nav.delegate = transitionController
        print("presentChatPost")
        //nav.pushViewController(galleryViewController, animated: true)
        transitionController.push(viewController: galleryViewController, on: self, attached: galleryViewController)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            break
        default:
            let controller = UserProfileViewController()
            controller.uid = partner.uid
            self.navigationController?.pushViewController(controller, animated: true)
            break
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return nil
        default:
            if partnerImage != nil {
                let image = JSQMessagesAvatarImageFactory.avatarImage(with: partnerImage!, diameter: 48)
                return image
            }
            
            return nil
        }
    }

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            cell.textView?.textColor = UIColor.white
        default:
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    
    override func collectionView
        
        (_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let currentItem = self.messages[indexPath.item]
        
        if indexPath.item == 0 && messages.count > 8 {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: currentItem.date)
        }
        
        
        if indexPath.item > 0 {
            let prevItem    = self.messages[indexPath.item-1]
            
            let gap = currentItem.date.timeIntervalSince(prevItem.date)
            
            if gap > 1800 {
                return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: currentItem.date)
            }
        } else {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: currentItem.date)
        }
        
        
        return nil
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if indexPath.item == 0 && messages.count > 8 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        if indexPath.item > 0 {
            let currentItem = self.messages[indexPath.item]
            let prevItem    = self.messages[indexPath.item-1]
            
            let gap = currentItem.date.timeIntervalSince(prevItem.date)//timeIntervalSinceDate(prevItem.date)
            
            if gap > 1800 {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
            
            if prevItem.senderId != currentItem.senderId {
                return 1.0
            } else {
                return 0.0
            }
        }  else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 0.0
    }

        
    var loadingNextBatch = false
    var downloadRef:DatabaseReference?
    
    var lastTimeStamp:Double?
    var limit:UInt = 16

}

//MARK - Setup
extension ChatViewController {
    
    func setup() {
        self.senderId = mainStore.state.userState.uid
        self.senderDisplayName = ""
    }
    
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        UserService.getHTTPSHeaders() { HTTPHeaders in
            guard let headers = HTTPHeaders else { return }
            
            let params = [
                "sender": userState.uid,
                "recipient": self.partner.uid,
                "text": text
            ] as [String:Any]
            
            Alamofire.request("\(API_ENDPOINT)/message", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                DispatchQueue.main.async {
                    if let json = response.result.value as? [String:Any], let success = json["success"] as? Bool {
                        
                        if !success, let msg = json["msg"] as? String {
                            return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: msg)
                        }
                        
                    } else {
                        
                        return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Unable to send message.")
                    }
                }
            }
        }
        
        return self.finishSendingMessage(animated: true)
        
        
    }
    
    func downloadMessages() {
        
        self.messages = []

        downloadRef?.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit).observe(.childAdded, with: { snapshot in
            let dict = snapshot.value as! [String:AnyObject]
            
            let senderId  = dict["sender"] as! String
            let timestamp = dict["timestamp"] as! Double
            
            let date = NSDate(timeIntervalSince1970: timestamp/1000)
            
            if let uploadKey = dict["uploadKey"] as? String, let uploadURL = dict["uploadURL"] as? String {
                let mediaItem = AsyncPhotoMediaItem(key: uploadKey, withURL: uploadURL)
                let mediaMessage = JSQMessage(senderId: senderId, senderDisplayName: "", date: date as Date!, media: mediaItem)
                self.messages.append(mediaMessage!)
                self.reloadMessagesView()
                self.stopActivityIndicator()
                self.finishReceivingMessage(animated: true)
                
            } else if let text = dict["text"] as? String {
                let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date as Date!, text: text)
                self.messages.append(message!)
                self.reloadMessagesView()
                self.stopActivityIndicator()
                self.finishReceivingMessage(animated: true)
            }
        
        })
    }

}


extension ChatViewController: View2ViewTransitionPresenting {
    
    func cameraButtonView() -> UIView {
        return UIView()
    }
    
    func topView() -> UIView {
        return UIView()
    }
    
    func bottomView() -> UIView {
        return UIView()
    }

    
    func initialFrame(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        print("initialFrame")
        guard let indexPath: IndexPath = userInfo?["initialIndexPath"] as? IndexPath else {
            return CGRect.zero
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? JSQMessagesCollectionViewCell else {
            return CGRect.zero
        }
        
        let data = messages[indexPath.row]
        if data.isMediaMessage, let media = data.media as? AsyncPhotoMediaItem {
            return media.asyncImageView.convert(media.asyncImageView.frame, to: self.view)
        }

        return CGRect.zero

    }
    
    func initialView(_ userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        print("ITS A CHATPOST TING")
        let indexPath: IndexPath = userInfo!["initialIndexPath"] as! IndexPath
        
        let data = messages[indexPath.row]
        if data.isMediaMessage, let media = data.media as? AsyncPhotoMediaItem {
            return media.asyncImageView
        }
        

        return UIView()

    }
    
    func prepareInitialView(_ userInfo: [String : AnyObject]?, isPresenting: Bool) {
           }
    
    func dismissInteractionEnded(_ completed: Bool) {}
    
}


class AsyncPhotoMediaItem: JSQPhotoMediaItem {
    var asyncImageView: UIImageView!
    var uploadKey:String!
    var item:StoryItem?
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    init(key:String, withURL url: String) {
        super.init()

        let size = UIScreen.main.bounds
        asyncImageView = UIImageView()
        asyncImageView.frame = CGRect(x: 0, y: 0, width: size.width * 0.3, height: size.height * 0.22)
        asyncImageView.contentMode = .scaleAspectFill
        asyncImageView.clipsToBounds = true
        asyncImageView.layer.cornerRadius = 6
        asyncImageView.backgroundColor = UIColor.jsq_messageBubbleLightGray()
        
        
        
        let activityIndicator = JSQMessagesMediaPlaceholderView.withActivityIndicator()
        activityIndicator?.frame = asyncImageView.frame
        asyncImageView.addSubview(activityIndicator!)
        
        UploadService.getUpload(key: key, completion: { item in
            if item != nil && url == item!.downloadUrl.absoluteString {
                self.item = item!
                loadImageUsingCacheWithURL(item!.downloadUrl.absoluteString, completion: { image, fromCache in
                    if image != nil {
                        self.asyncImageView.image = image!
                        activityIndicator?.removeFromSuperview()
                    }
                })
            } else {
                activityIndicator?.removeFromSuperview()
                self.item = nil
                self.asyncImageView.image = nil
            }
        })
        
    }
    
    override func mediaView() -> UIView! {
        return asyncImageView
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        return asyncImageView.frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
