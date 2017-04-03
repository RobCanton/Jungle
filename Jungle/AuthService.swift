//
//  AuthService.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-24.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import Firebase


class AuthService: NSObject {
    
    static let sharedInstance : AuthService = {
        let instance = AuthService()
        return instance
    }()
    
    
    
    override init() {
        super.init()
        
    }
    
    func logout() {
        mainStore.dispatch(ClearAllNotifications())
        mainStore.dispatch(ClearConversations())
        Listeners.stopListeningToAll()
        mainStore.dispatch(ClearSocialState())
        mainStore.dispatch(UserIsUnauthenticated())
        try! FIRAuth.auth()!.signOut()
        globalMainRef?.dismiss(animated: false, completion: nil)
    }

}

