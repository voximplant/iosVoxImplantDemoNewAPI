/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import UserNotifications


var voxController:VIController!
var cameraPreprocessor:CameraPreprocessor!
var customCameraSource:CustomCameraSource!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Log.info("VoxImplantDemo started \(VoxImplantVersionNumber)")
        voxController = VIController()
        
        // uncomment to use camera preprocess callback
        //cameraPreprocessor = CameraPreprocessor()
        customCameraSource = CustomCameraSource()
        
        registerForPushNotifications()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        Log.info("VoxImplantDemo === applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Log.info("VoxImplantDemo === applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        Log.info("VoxImplantDemo === applicationWillEnterForeground")

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Log.info("VoxImplantDemo === applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        Log.info("VoxImplantDemo === applicationWillTerminate")
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        Log.info("VoxImplantDemo: received push notification")
        
        let notificationProcessing = VIMessengerPushNotificationProcessing.shared()
        
        let messengerEvent = (notificationProcessing?.processPushNotification(userInfo) as! VIMessageEvent)
        Log.info("event = \(messengerEvent.eventType.rawValue), text = \(messengerEvent.message.text)")
        
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 0) as Date
        notification.alertBody = messengerEvent.message.text
        notification.alertAction = "open"
        notification.hasAction = true
        notification.soundName = "note.aiff"
        notification.userInfo = ["UUID": "reminderID" ]
        UIApplication.shared.scheduleLocalNotification(notification)
        
        completionHandler(UIBackgroundFetchResult.newData);
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        voxController.imPushToken = deviceToken
        
        let token = tokenParts.joined()
        Log.info("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.info("Failed to register: \(error)")
    }
    
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            Log.info("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            Log.info("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async(execute: {
                UIApplication.shared.registerForRemoteNotifications()
            })
        }
    }
}

