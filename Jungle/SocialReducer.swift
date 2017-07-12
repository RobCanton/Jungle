//
//  SocialReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift

enum FollowingStatus {
    case None, Following, Requested, CurrentUser
}

func checkFollowingStatus (uid:String) -> FollowingStatus {
    
    let current_uid = mainStore.state.userState.uid
    if uid == current_uid {
        return .CurrentUser
    }
    
    let following = mainStore.state.socialState.following
    if following.contains(uid) {
        return .Following
    }

    return .None
}



func SocialReducer(action: Action, state:SocialState?) -> SocialState {
    var state = state ?? SocialState()
    
    switch action {
    case _ as AddFollower:
        let a = action as! AddFollower
        state.followers.insert(a.uid)
        print("New follower")
        break
    case _ as RemoveFollower:
        let a = action as! RemoveFollower
        state.followers.remove(a.uid)
        break
    case _ as AddFollowing:
        let a = action as! AddFollowing
        state.following.insert(a.uid)
        print("New following")
        break
    case _ as RemoveFollowing:
        let a = action as! RemoveFollowing
        state.following.remove(a.uid)
        print("Removed following")
        break
    case _ as AddBlockedUser:
        let a = action as! AddBlockedUser
        state.blocked.insert(a.uid)
        break
    case _ as RemoveBlockedUser:
        let a = action as! RemoveBlockedUser
        state.blocked.remove(a.uid)
        break
    case _ as AddBlockedAnonymousUser:
        let a = action as! AddBlockedAnonymousUser
        state.blockedAnonymous.append((a.aid, a.timestamp))
        break
    case _ as RemoveBlockedAnonymousUser:
        let a = action as! RemoveBlockedAnonymousUser
        for i in 0..<state.blockedAnonymous.count {
            let entry = state.blockedAnonymous[i]
            if entry.0 == a.aid {
                state.blockedAnonymous.remove(at: i)
                break
            }
        }
        break
    case _ as ClearSocialState:
        state = SocialState()
        break
    default:
        break
    }
    
    return state
}

func isAnonBlocked(_ aid:String) -> Bool{
    for (id,_) in mainStore.state.socialState.blockedAnonymous {
        if id == aid { return true }
    }
    return false
}

struct AddFollower: Action {
    let uid: String
}

struct RemoveFollower: Action {
    let uid: String
}

struct AddFollowing: Action {
    let uid: String
}

struct RemoveFollowing: Action {
    let uid: String
}

struct AddBlockedUser: Action {
    let uid: String
}

struct RemoveBlockedUser: Action {
    let uid: String
}


struct AddBlockedAnonymousUser: Action {
    let aid: String
    let timestamp:Double
}

struct RemoveBlockedAnonymousUser: Action {
    let aid: String
}

struct ClearSocialState: Action {}
