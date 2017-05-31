//
//  MessageService.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-22.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import ReSwift


protocol MessageServiceProtocol:ServiceProtocol {
    func conversationsUpdated(_ conversations: [Conversation])
}


class MessageService: Service {
    
    private(set) var conversations:[Conversation]!

    override init(_ subscribers:[String:ServiceProtocol]) {
        super.init(subscribers)
       
        conversations = []
        
    }
    
    internal override func subscribe(_ name: String, subscriber: ServiceProtocol) {
        if let s = subscriber as? MessageServiceProtocol {
            super.subscribe(name, subscriber: s)
            s.conversationsUpdated(self.conversations)
        }
    }
    
    fileprivate func getSubscribers() -> [String:MessageServiceProtocol]? {
        guard let subscribers = subscribers as? [String:MessageServiceProtocol] else { return nil }
        return subscribers
    }
    
    fileprivate func updateSubscribers() {
        guard let subscribers = getSubscribers() else { return }
        self.conversations.sort(by: { $0 > $1 })
        subscribers.forEach({ $0.value.conversationsUpdated(self.conversations) })
    }
    
    internal func clear() {
        conversations = []
        clearSubscribers()
    }
    
    internal func startListeningToConversations() {
        let uid = mainStore.state.userState.uid
        let conversationsRef = Database.database().reference().child("users/conversations/\(uid)")
        conversationsRef.observe(.childAdded, with: { snapshot in
            if snapshot.exists() {
                
                let partner = snapshot.key
                let pairKey = createUserIdPairKey(uid1: uid, uid2: partner)
                if let dict = snapshot.value as? [String:AnyObject]{
                    
                    if dict["blocked"] != nil {
                        self.removeConversation(pairKey)
                    } else {
                        let seen = dict["seen"] as! Bool
                        let lastMessage = dict["text"] as! String
                        let timestamp = dict["latest"] as! Double
                        let date = Date(timeIntervalSince1970: timestamp/1000) as Date
                        let listening = true

                        let conversation = Conversation(key: pairKey, partner_uid: partner, seen: seen, date: date, lastMessage: lastMessage, listening: listening)
                        self.conversations.append(conversation)
                        self.updateSubscribers()
                    }
                }
            }
        })
        
        conversationsRef.observe(.childChanged, with: { snapshot in
            if snapshot.exists() {
                
                let partner = snapshot.key
                let pairKey = createUserIdPairKey(uid1: uid, uid2: partner)
                if let dict = snapshot.value as? [String:AnyObject] {
                    if dict["blocked"] != nil {
                        self.removeConversation(pairKey)
                    } else {
                        let seen = dict["seen"] as! Bool
                        let lastMessage = dict["text"] as! String
                        let timestamp = dict["latest"] as! Double
                        let date = Date(timeIntervalSince1970: timestamp/1000) as Date
                        let listening = true
                        
                        let conversation = Conversation(key: pairKey, partner_uid: partner, seen: seen, date: date, lastMessage: lastMessage, listening: listening)
                        self.changeConversation(conversation)
                    }
                    
                }
            }
            
        })
    }
    
    internal func stopListeningToConversatons() {
        let uid = mainStore.state.userState.uid
        let conversationsRef = Database.database().reference().child("users/conversations/\(uid)")
        conversationsRef.removeAllObservers()
    }
    
    fileprivate func changeConversation(_ conversation: Conversation) {
        var index:Int?
        for i in 0..<conversations.count {
            let c = conversations[i]
            if c.getKey() == conversation.getKey() {
                index = i
            }
        }
        if index != nil {
            conversations[index!] = conversation
        } else {
            conversations.append(conversation)
        }
        self.updateSubscribers()
    }
    
    fileprivate func removeConversation(_ key: String) {
        var index:Int?
        for i in 0..<conversations.count {
            if conversations[i].getKey() == key {
                index = i
            }
        }
        if index != nil {
            self.conversations.remove(at: index!)
            self.updateSubscribers()
        }
    }
}

func createUserIdPairKey(uid1:String, uid2:String) -> String {
    var uids = [uid1, uid2]
    uids.sort()
    return "\(uids[0]):\(uids[1])"
}
