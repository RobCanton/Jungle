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
    var settingsState: SettingsState
    var socialState: SocialState
    var supportedVersion:Bool = false
    var viewed = [String]()
}

struct SocialState {
    var followers = Tree<String>()
    var following = Tree<String>()
    var blocked = Tree<String>()
    var blockedAnonymous = [(String,Double)]()
}


struct AppReducer: Reducer {
    typealias ReducerStateType = AppState
    
    func handleAction(action: Action, state: AppState?) -> AppState {
        
        return AppState(
            userState: UserStateReducer(action, state: state?.userState),
            settingsState: SettingsReducer(action, state: state?.settingsState),
            socialState: SocialReducer(action: action, state: state?.socialState),
            supportedVersion: SupportedVersionReducer(action, state: state?.supportedVersion),
            viewed: ViewedReducer(action, state: state?.viewed)
        )
    }
}



func ViewedReducer(_ action: Action, state:[String]?) -> [String] {
    var state = state ?? [String]()
    switch action {
    case _ as SetViewed:
        let a = action as! SetViewed
        state = a.postKeys
        break
    case _ as ClearViewed:
        state = [String]()
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

struct SetViewed: Action {
    let postKeys:[String]
}

struct ClearViewed: Action {}
