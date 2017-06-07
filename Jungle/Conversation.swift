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
    private var seen:Bool
    private var date:Date
    private(set)  var sender:String
    private var lastMessage:String
    private(set) var isMediaMessage:Bool
    private var partner:User?
    private var listening:Bool
    var delegate:GetUserProtocol?
    
    init(key:String, partner_uid:String, seen:Bool, date:Date, sender:String, lastMessage:String, isMediaMessage:Bool, listening:Bool)
    {
        self.key         = key
        self.partner_uid = partner_uid
        self.seen        = seen
        self.date        = date
        self.sender      = sender
        self.lastMessage = lastMessage
        self.isMediaMessage = isMediaMessage
        self.listening   = listening
        
        super.init()
        
        //retrieveUser()
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
    
    func getSeen() -> Bool {
        return seen
    }
    
    func setSeenTo(_ value:Bool) {
        seen = value
    }
    
    func getDate() -> Date {
        return date
    }
    
    func getLastMessage() -> String {
        return lastMessage
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
    
}

func < (lhs: Conversation, rhs: Conversation) -> Bool {
    return lhs.getDate().compare(rhs.getDate()) == .orderedAscending
}

func == (lhs: Conversation, rhs: Conversation) -> Bool {
    return lhs.getDate().compare(rhs.getDate()) == .orderedSame
}
