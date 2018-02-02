/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit

class Notify {
    static let disconnected = Notification.Name("disconnected")
    
    static let incomingPush = Notification.Name("incomingPush")
    
    static let loginSuccess = Notification.Name("LoginSuccess")
    static let loginFailed = Notification.Name("LoginFailed")
    
    
    // following two messages used only on simulator because CallKit not works on sim
    static let incomingCall = Notification.Name("incomingCall")
    static let cancelIncomingCall = Notification.Name("cancelIncomingCall")
    
    
    
    static let acceptIncomingCall = Notification.Name("acceptIncomingCall")
    static let rejectIncomingCall = Notification.Name("rejectIncomingCall")
    
    static func post(name: Notification.Name) {
        Notify.post(name: name, userInfo: nil)
    }
    
    static func post(name: Notification.Name, userInfo:[AnyHashable : Any]?) {
        let notify = Notification(name: name, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notify)
    }
}
