//
//  ConversationsReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift
import JSQMessagesViewController

func getNonEmptyConversations() -> [Conversation] {
    var activeConvos = [Conversation]()
    for conversation in mainStore.state.conversations {
        let isBlocked = mainStore.state.socialState.blockedBy.contains(conversation.getPartnerId())
        if conversation.lastMessage != nil && conversation.isListening() && !isBlocked {
            activeConvos.append(conversation)
        }
    }
    return activeConvos
}

func checkForExistingConversation(partner_uid:String) -> Conversation? {
    for conversation in mainStore.state.conversations {
        if conversation.getPartnerId() == partner_uid {
            return conversation
        }
    }
    return nil
}

func findConversation(key:String) -> Conversation? {
    for conversation in mainStore.state.conversations {
        if conversation.getKey() == key {
            return conversation
        }
    }
    return nil
}

func userHasSeenMessage(seen:NSDate?, message:JSQMessage?) -> Bool{
    if seen != nil && message != nil {
        if message!.senderId == mainStore.state.userState.uid {
            return true
        }
        let diff = seen!.compare(message!.date)
        if diff == .orderedAscending {
            return false
        }
    }
    else if message != nil {
        return false
    }
    return true
}

func createUserIdPairKey(uid1:String, uid2:String) -> String {
    var uids = [uid1, uid2]
    uids.sort()
    return "\(uids[0]):\(uids[1])"
}

func ConversationsReducer(action: Action, state:[Conversation]?) -> [Conversation] {
    var state = state ?? [Conversation]()
    switch action {
    case _ as ConversationAdded:
        let a = action as! ConversationAdded
        state.append(a.conversation)
        break
    case _ as NewMessageInConversation:
        let a = action as! NewMessageInConversation
        if let conversation = findConversation(key: a.conversationKey) {
            conversation.lastMessage = a.message
            conversation.seen = userHasSeenMessage(seen: conversation.seenDate, message: conversation.lastMessage)
        }
        break
    case _ as SeenConversation:
        let a = action as! SeenConversation
        if let conversation = findConversation(key: a.conversationKey) {
            conversation.seenDate = a.seenDate
            conversation.seen = userHasSeenMessage(seen: conversation.seenDate, message: conversation.lastMessage)
        }
        break
    case _ as MuteConversation:
        let a = action as! MuteConversation
        if let conversation = findConversation(key: a.conversationKey) {
            conversation.mute()
        }
        break
    case _ as UnmuteConversation:
        let a = action as! UnmuteConversation
        if let conversation = findConversation(key: a.conversationKey) {
            conversation.listen()
        }
        break
    case _ as ClearConversations:
        state = [Conversation]()
        break
    default:
        break
    }
    return state
}


struct OpenConversation: Action {
    let uid: String
}

struct ConversationOpened: Action {
}

struct ConversationAdded: Action {
    let conversation:Conversation
}

struct NewMessageInConversation: Action {
    let message:JSQMessage
    let conversationKey:String
}

struct SeenConversation: Action {
    let seenDate:NSDate
    let conversationKey:String
}

struct MuteConversation:Action {
    let conversationKey:String
}

struct UnmuteConversation:Action {
    let conversationKey:String
}

/* Destructive Actions */

struct ClearConversations: Action {}
