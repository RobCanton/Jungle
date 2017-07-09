//
//  UserStateReducer.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-01.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import ReSwift

struct UserState {
    var isAuth: Bool = false
    var uid: String = ""
    var user:User?
    var anonID:String?
    var anonMode = false
}

func UserStateReducer(_ action: Action, state: UserState?) -> UserState {
    var state = state ?? UserState()
    switch action {
    case _ as UserIsAuthenticated:
        let a = action as! UserIsAuthenticated
        state.isAuth = true
        state.uid = a.user.uid
        state.user = a.user
        break
    case _ as UserIsUnauthenticated:
        Listeners.stopListeningToAll()
        state = UserState()
        break
    case _ as UpdateUser:
        let a = action as! UpdateUser
        state.user = a.user
        break
    case _ as FIRUserUpdated:
        break
    case _ as SetAnonID:
        let a = action as! SetAnonID
        state.anonID = a.id
        break
    case _ as GoAnonymous:
        state.anonMode = true
        break
    case _ as GoPublic:
        state.anonMode = false
        break
    case _ as ToggleAnonMode:
        state.anonMode = !state.anonMode
        break
    default:
        break
    }
    
    return state
}

struct FIRUserUpdated: Action {}

struct UserIsAuthenticated: Action {
    let user: User
}

struct UserIsUnauthenticated: Action {}

struct UpdateUser: Action {
    let user: User
}

struct SupportedVersion: Action {}

struct SetAnonID: Action {
    let id:String
}

struct GoPublic: Action {}
struct GoAnonymous: Action {}

struct ToggleAnonMode: Action {}
