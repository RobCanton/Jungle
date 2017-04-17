//
//  AppState.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-30.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import ReSwift

struct AppState: StateType {
    var nearbyPlacesActivity = [LocationStory]()
    var followingActivity = [UserStory]()
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
            nearbyPlacesActivity: NearbyPlacesActivityReducer(action, state: state?.nearbyPlacesActivity),
            followingActivity: FollowingActivityReducer(action, state: state?.followingActivity),
            userState: UserStateReducer(action, state: state?.userState),
            conversations:ConversationsReducer(action: action, state: state?.conversations),
            socialState: SocialReducer(action: action, state: state?.socialState),
            supportedVersion: SupportedVersionReducer(action, state: state?.supportedVersion),
            notifications: NotificationsReducer(action, state: state?.notifications)
        )
    }
}

func NearbyPlacesActivityReducer(_ action: Action, state:[LocationStory]?) -> [LocationStory] {
    var state = state ?? [LocationStory]()
    
    switch action {
    case _ as SetNearbyPlacesActivity:
        let a = action as! SetNearbyPlacesActivity
        state = a.stories
        break
    case _ as ClearNearbyPlacesActivity:
        state = []
        break
    default:
        break
    }
    return state
}

func FollowingActivityReducer(_ action: Action, state:[UserStory]?) -> [UserStory] {
    var state = state ?? [UserStory]()
    
    switch action {
    case _ as SetFollowingActivity:
        let a = action as! SetFollowingActivity
        state = a.stories
        break
    case _ as ClearFollowingActivity:
        state = []
        break
    default:
        break
    }
    return state
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
    case _ as RemoveNotification:
        let a = action as! RemoveNotification
        state[a.notificationKey] = nil
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

struct RemoveNotification: Action {
    let notificationKey:String
}

struct MarkAllNotifcationsAsSeen: Action {}

struct ClearAllNotifications: Action {}

struct SetNearbyPlacesActivity: Action {
    let stories:[LocationStory]
}

struct ClearNearbyPlacesActivity: Action {}

struct SetFollowingActivity: Action {
    let stories:[UserStory]
}

struct ClearFollowingActivity: Action {}
