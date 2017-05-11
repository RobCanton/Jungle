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
import UserNotifications
import SwiftMessages

//UIColor(red: 15/255, green: 226/255, blue: 117/255, alpha: 1.0) //#0fe275
//let lightAccentColor = UIColor(red: 220/266, green: 227/255, blue: 91/255, alpha: 1.0)
//let darkAccentColor = UIColor(red: 69/266, green: 182/255, blue: 73/255, alpha: 1.0)
let lightAccentColor = UIColor(red: 140/266, green: 216/255, blue: 86/255, alpha: 1.0)
let darkAccentColor = UIColor(red: 2/255, green: 217/255, blue: 87/255, alpha: 1.0)
let photoCellColorAlpha:CGFloat = 1.0

let accentColor = UIColor(red: 2/255, green: 217/255, blue: 87/255, alpha: 1.0)//UIColor(red: 0/255, green: 224/255, blue: 108/255, alpha: 1.0) //#0fe275
let errorColor = UIColor(red: 1, green: 110/255, blue: 110/255, alpha: 1.0)
let GMSAPIKEY = "AIzaSyAdmbnsaZbK-8Q9EvuKh2pAcQ5p7Q6OKNI"

let mainStore = Store<AppState>(
    reducer: AppReducer(),
    state: nil
)

var remoteConfig: FIRRemoteConfig?


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var connection_timer:Timer?
    var alertWrapper = SwiftMessages()
    var no_connection_alerted = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        //checkInternetConnection()
        
        connection_timer?.invalidate() // just in case this button is tapped multiple times
        // start the timer
        connection_timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(checkInternetConnection), userInfo: nil, repeats: true)
        
        
        GMSPlacesClient.provideAPIKey(GMSAPIKEY)
        GMSServices.provideAPIKey(GMSAPIKEY)
        FIRApp.configure()
        
        remoteConfig = FIRRemoteConfig.remoteConfig()
        let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig?.configSettings = remoteConfigSettings!
        remoteConfig?.setDefaultsFromPlistFileName("RemoteConfigDefaults")
        fetchConfig()
        
        if #available(iOS 10, *) {
            UITabBarItem.appearance().badgeColor = .orange
        }
        
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
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]){
                (granted,error) in
                if granted{
                    application.registerForRemoteNotifications()
                } else {
                    print("User Notification permission denied: \(String(describing: error?.localizedDescription))")
                }
                
            }
        } else {
            // Fallback on earlier versions
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        return true
    }
    
    func checkInternetConnection() {
        if Reachability.isConnectedToNetwork(){
            if no_connection_alerted {
                print("Internet Connection Available!")
                no_connection_alerted = false
            }
            alertWrapper.hideAll()
        }else{
            if !no_connection_alerted {
                print("Internet Connection not Available!")
                no_connection_alerted = true
                //Alerts.showNoInternetConnectionAlert(inWrapper: alertWrapper)
            }
        }
    }
    
    func fetchConfig() {
        guard let remoteConfig = remoteConfig else { return }
        var expirationDuration = 3600
        // If your app is using developer mode, expirationDuration is set to 0, so each fetch will
        // retrieve values from the service.
        if remoteConfig.configSettings.isDeveloperModeEnabled {
            expirationDuration = 0
        }
        
        // [START fetch_config_with_callback]
        // TimeInterval is set to expirationDuration here, indicating the next fetch request will use
        // data fetched from the Remote Config service, rather than cached parameter values, if cached
        // parameter values are more than expirationDuration seconds old. See Best Practices in the
        // README for more information.
        remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                remoteConfig.activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(error!.localizedDescription)")
            }
            
        }
        // [END fetch_config_with_callback]
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //TODO: Add code here later to deal with tokens.
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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
