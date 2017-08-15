//
//  SettingsReducer.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-15.
//  Copyright © 2017 Robert Canton. All rights reserved.
//


import ReSwift

struct SettingsState {
    var allowFlaggedContent = false
    var uploadWarningShown = false
    var commentsSortingMode = CommentsSortedBy.date
}

func SettingsReducer(_ action: Action, state: SettingsState?) -> SettingsState {
    var state = state ?? SettingsState()
    switch action {
    case _ as AllowFlaggedContent:
        state.allowFlaggedContent = true
        break
    case _ as BlockFlaggedContent:
        state.allowFlaggedContent = false
        break
    case _ as UploadWarningShown:
        state.uploadWarningShown = true
    case _ as ResetSettings:
        state = SettingsState()
        break
    case _ as SetCommentsSortMode:
        let a = action as! SetCommentsSortMode
        state.commentsSortingMode = a.mode
        break
    default:
        break
    }
    
    return state
}


struct AllowFlaggedContent: Action {}

struct BlockFlaggedContent: Action {}

struct ResetSettings: Action {}

struct UploadWarningShown: Action {}

struct SetCommentsSortMode: Action {
    let mode:CommentsSortedBy
}
