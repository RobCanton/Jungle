//
//  AppDelegate.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-15.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Firebase
import ReSwift
import AVFoundation

//UIColor(red: 15/255, green: 226/255, blue: 117/255, alpha: 1.0) //#0fe275

let accentColor = UIColor(red: 83/255, green: 226/255, blue: 0/255, alpha: 1.0)//UIColor(red: 0/255, green: 224/255, blue: 108/255, alpha: 1.0) //#0fe275
let GMSAPIKEY = "AIzaSyAdmbnsaZbK-8Q9EvuKh2pAcQ5p7Q6OKNI"

let mainStore = Store<AppState>(
    reducer: AppReducer(),
    state: nil
)


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSPlacesClient.provideAPIKey(GMSAPIKEY)
        GMSServices.provideAPIKey(GMSAPIKEY)
        FIRApp.configure()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            //print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                //print("AVAudioSession is Active")
            } catch _ as NSError {
                //print(error.localizedDescription)
            }
        } catch _ as NSError {
            //print(error.localizedDescription)
        }
               
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        clearTmpDirectory()
    }
    
    func clearTmpDirectory() {
        print("Clear temp directory")
        do {
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach { file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }


}

