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




class ChatViewController: JSQMessagesViewController, GetUserProtocol {
    
    var popUpMode = false
    var refreshControl: UIRefreshControl!

    //var containerDelegate:ContainerViewController?
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor(white: 0.85, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: accentColor)
    var messages:[JSQMessage]!
    
    var settingUp = true
    
    var conversationKey:String!
    var partner:User!
    var partnerImage:UIImage?
    

    func userLoaded(user: User) {
        partner = user
       
    }

    var activityIndicator:UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        if !popUpMode {
            self.addNavigationBarBackdrop()
        }
        
        messages = [JSQMessage]()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        self.inputToolbar.contentView.leftBarButtonItemWidth = 0
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        collectionView?.collectionViewLayout.springinessEnabled = true
        collectionView?.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x:0,y:0,width:50,height:50))
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.center = CGPoint(x:UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2 - 50)
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    
        conversationKey = createUserIdPairKey(uid1: mainStore.state.userState.uid, uid2: partner.uid)
        title = partner.username
        
        downloadRef = UserService.ref.child("conversations/\(conversationKey!)/messages")
        
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
        
//        if !popUpMode {
//            sheet.addAction(UIAlertAction(title: "View User Profile", style: .default, handler: { _ in
//                let controller = UserProfileViewController()
//                controller.uid = self.partner.uid
//                self.navigationController?.pushViewController(controller, animated: true)
//            }))
//        }
        
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
                    let value = messageSnap.value as! [String: Any]
                    let senderId  = value["senderId"] as! String
                    let text      = value["text"] as! String
                    let timestamp = value["timestamp"] as! Double

                    if timestamp != endTimestamp {
                        let date = Date(timeIntervalSince1970: timestamp/1000)
                        let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                        messageBatch.append(message!)
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
        //self.navigationController?.navigationBar.isUserInteractionEnabled = true
        
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
        //set seen timestamp
        if messages.count > 0 {
            let lastMessage = messages[messages.count - 1]
            let uid = mainStore.state.userState.uid
            if lastMessage.senderId != uid {
                let ref = UserService.ref.child("conversations/\(conversationKey!)/meta/\(uid)")
                ref.setValue([".sv":"timestamp"])
            }
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
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
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
            }
        }  else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
            let prevItem = indexPath.item - 1
            
            if prevItem >= 0 {
                let prevMessage = messages[prevItem]
                if prevMessage.isMediaMessage {
                    return kJSQMessagesCollectionViewCellLabelHeightDefault
                }
            }
            return 0.0
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let prevItem = indexPath.item - 1
        
        if prevItem >= 0 {
            let prevMessage = messages[prevItem]
            if prevMessage.isMediaMessage {
                return NSAttributedString(string: "            Temporary message.", attributes: nil)
            }
        }
        return NSAttributedString(string: "")
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
        UserService.sendMessage(conversationKey: conversationKey, recipientId: partner.uid, message: text, completion: nil)
        self.finishSendingMessage(animated: true)
        
    }
    
    func downloadMessages() {
        
        self.messages = []

        downloadRef?.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit).observe(.childAdded, with: { snapshot in
            let dict = snapshot.value as! [String:AnyObject]
        
            let senderId  = dict["senderId"] as! String
            let text      = dict["text"] as! String
            let timestamp = dict["timestamp"] as! Double
            
            let date = NSDate(timeIntervalSince1970: timestamp/1000)

            let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date as Date!, text: text)
            self.messages.append(message!)
            self.reloadMessagesView()
            self.stopActivityIndicator()
            self.finishReceivingMessage(animated: true)
            //
        
        })
    }

}

class AsyncPhotoMediaItem: JSQPhotoMediaItem {
    var asyncImageView: UIImageView!
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    init(withURL url: String) {
        super.init()

        let size = UIScreen.main.bounds
        asyncImageView = UIImageView()
        asyncImageView.frame = CGRect(x: 0, y: 0, width: size.width * 0.5, height: size.height * 0.35)
        asyncImageView.contentMode = .scaleAspectFill
        asyncImageView.clipsToBounds = true
        asyncImageView.layer.cornerRadius = 5
        asyncImageView.backgroundColor = UIColor.jsq_messageBubbleLightGray()
        
        let activityIndicator = JSQMessagesMediaPlaceholderView.withActivityIndicator()
        activityIndicator?.frame = asyncImageView.frame
        asyncImageView.addSubview(activityIndicator!)
        
        
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            if image != nil {
                self.asyncImageView.image = image!
                activityIndicator?.removeFromSuperview()
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
