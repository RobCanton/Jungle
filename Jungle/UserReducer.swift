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
}

func UserStateReducer(_ action: Action, state: UserState?) -> UserState {
    var state = state ?? UserState()
    switch action {
    case _ as UserIsAuthenticated:
        let a = action as! UserIsAuthenticated
        state.isAuth = true
        state.uid = a.user.getUserId()
        state.user = a.user
        break
        
    case _ as UserIsUnauthenticated:
        state = UserState()
        break
        
    case _ as UpdateUser:
        let a = action as! UpdateUser
        state.user = a.user
        break
    default:
        break
    }
    
    return state
}


struct UserIsAuthenticated: Action {
    let user: User
}

struct UserIsUnauthenticated: Action {}

struct UpdateUser: Action {
    let user: User
}



struct SupportedVersion: Action {}
