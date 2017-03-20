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
        
        break
    case _ as RemoveFollower:
        let a = action as! RemoveFollower
        state.followers.remove(a.uid)
        break
    case _ as AddFollowing:
        let a = action as! AddFollowing
        state.following.insert(a.uid)
        break
    case _ as RemoveFollowing:
        let a = action as! RemoveFollowing
        state.following.remove(a.uid)
        break
    case _ as AddBlocked:
        let a = action as! AddBlocked
        state.blocked.insert(a.uid)
        print("Blocked User Added: \(a.uid)")
        break
    case _ as RemoveBlocked:
        let a = action as! RemoveBlocked
        state.blocked.remove(a.uid)
        print("Blocked User Removed: \(a.uid)")
        break
    case _ as AddBlockedBy:
        let a = action as! AddBlockedBy
        state.blockedBy.insert(a.uid)
        print("BlockedBy User Added: \(a.uid)")
        break
    case _ as RemoveBlockedBy:
        let a = action as! RemoveBlockedBy
        state.blockedBy.remove(a.uid)
        print("BlockedBy User Removed: \(a.uid)")
        break
    case _ as ClearSocialState:
        
        state = SocialState()
        break
    default:
        break
    }
    
    return state
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

struct AddBlocked: Action {
    let uid: String
}

struct RemoveBlocked: Action {
    let uid: String
}

struct AddBlockedBy: Action {
    let uid: String
}

struct RemoveBlockedBy: Action {
    let uid: String
}

struct ClearSocialState: Action {}
