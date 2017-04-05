//
//  AppState.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-30.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import ReSwift

struct AppState: StateType {
    var userState: UserState
    var conversations = [Conversation]()
    var socialState: SocialState
    var supportedVersion:Bool = false
    var notifications = [String:Bool]()
}



struct SocialState {
    var followers = Tree<String>()
    var following = Tree<String>()
    var blocked = Tree<String>()
    var blockedBy = Tree<String>()
}

struct AppReducer: Reducer {
    typealias ReducerStateType = AppState
    
    func handleAction(action: Action, state: AppState?) -> AppState {
        
        return AppState(
            userState: UserStateReducer(action, state: state?.userState),
            conversations:ConversationsReducer(action: action, state: state?.conversations),
            socialState: SocialReducer(action: action, state: state?.socialState),
            supportedVersion: SupportedVersionReducer(action, state: state?.supportedVersion),
            notifications: NotificationsReducer(action, state: state?.notifications)
        )
    }
}

func SupportedVersionReducer(_ action: Action, state:Bool?) -> Bool {
    var state = state ?? false
    
    switch action {
    case _ as SupportedVersion:
        state = true
        break
    default:
        break
    }
    return state
}


func NotificationsReducer(_ action: Action, state:[String:Bool]?) -> [String:Bool] {
    var state = state ?? [String:Bool]()
    switch action {
    case _ as AddNotification:
        let a = action as! AddNotification
        state[a.notificationKey] = a.seen
        break
    case _ as MarkAllNotifcationsAsSeen:
        for (key, seen) in state {
            if !seen {
                NotificationService.markNotificationAsSeen(key: key)
                state[key] = true
            }
        }
        break
    case _ as ClearAllNotifications:
        state = [String:Bool]()
        break
    default:
        break
    }
    return state
}

struct AddNotification: Action {
    let notificationKey: String
    let seen: Bool
}

struct MarkAllNotifcationsAsSeen: Action {}

struct ClearAllNotifications: Action {}
