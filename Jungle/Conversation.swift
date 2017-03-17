//
//  Conversation.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import Foundation
import JSQMessagesViewController

protocol GetUserProtocol {
    func userLoaded(user:User)
}

class Conversation: NSObject, Comparable {
    
    private var key:String
    private var partner_uid:String
    private var partner:User?
    private var listening:Bool {
        didSet {
            if listening {
                startListening()
            } else {
                stopListening()
            }
        }
    }
    
    private var conversationRef:FIRDatabaseReference?
    
    var lastMessage:JSQMessage?
    var seenDate:NSDate?
    
    var seen:Bool = true
    
    var delegate:GetUserProtocol?
    
    init(key:String, partner_uid:String, listening:Bool)
    {
        self.key         = key
        self.partner_uid = partner_uid
        self.listening   = listening
        
        super.init()
        
        retrieveUser()
        if self.listening {
            startListening()
        }
    }
    
    func getKey() -> String {
        return key
    }
    
    func getPartnerId() -> String {
        return partner_uid
    }
    
    func getPartner() -> User? {
        return partner
    }
    
    func mute() {
        listening = false
    }
    
    func listen() {
        listening = true
    }
    
    func isListening() -> Bool {
        return listening
    }
    

    func retrieveUser() {
        UserService.getUser(partner_uid, completion: { _user in
            if let user = _user {
                self.partner = user
                self.delegate?.userLoaded(user: self.partner!)
            }
        })
    }
    
    private func startListening() {
        stopListening()
        print("Start Listening to Conversation")
        conversationRef = UserService.ref.child("conversations/\(key)")
        conversationRef!.child("messages").queryLimited(toLast: 1).observe(.childAdded, with: { snapshot in
            print("HEYA!")
            if snapshot.exists() {
                let dict = snapshot.value as! [String:AnyObject]
                let senderId  = dict["senderId"] as! String
                let text      = dict["text"] as! String
                let timestamp = dict["timestamp"] as! Double
                let date      = Date(timeIntervalSince1970: timestamp/1000)
                let message   = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                mainStore.dispatch(NewMessageInConversation(message: message!, conversationKey: self.key))
            }
        })
        
        conversationRef!.child(mainStore.state.userState.uid).observe(.value, with: { snapshot in
            if snapshot.exists() {
                let dict = snapshot.value as! [String:AnyObject]
                var seenTimestamp:Double = 0
                if dict["seen"] != nil {
                    seenTimestamp = dict["seen"] as! Double
                }
                let seenDate = NSDate(timeIntervalSince1970: seenTimestamp/1000)
                mainStore.dispatch(SeenConversation(seenDate: seenDate, conversationKey: self.key))
            }
        })
    }
    
    private func stopListening() {
        print("Stop Listening to Conversation")
        conversationRef?.removeAllObservers()
    }
}

func < (lhs: Conversation, rhs: Conversation) -> Bool {
    let lhs_date = lhs.lastMessage!.date
    let rhs_date = rhs.lastMessage!.date
    return lhs_date!.compare(rhs_date!) == .orderedAscending
}

func == (lhs: Conversation, rhs: Conversation) -> Bool {
    let lhs_date = lhs.lastMessage!.date
    let rhs_date = rhs.lastMessage!.date
    return lhs_date!.compare(rhs_date!) == .orderedSame
}
