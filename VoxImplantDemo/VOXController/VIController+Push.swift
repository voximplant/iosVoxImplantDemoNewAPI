//
//  VIControllerPush.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 21.04.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import UIKit
import Foundation
import PushKit
import VoxImplant


extension Data {
    func tokenString() -> String{
        
        var string = ""
        for i in 0...self.count-1{
            string = string.appendingFormat("%02.2hhx", self[i])
        }
        return string
    }
}

extension VIController: PKPushRegistryDelegate {
    
    func registerForPushNotifications() {
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {
        Log.debug("credentials.token = \(credentials.token.tokenString()) type = \(type)")
        self.voipPushToken = credentials.token
    }
    
    static func appState() -> String {
        switch UIApplication.shared.applicationState {
        case .active:       return "active"
        case .inactive:     return "inactive"
        case .background:   return "background"
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        Log.debug(" === didReceiveIncomingPushWith = \(payload) type = \(type)")
        
        
        let voximplant = payload.dictionaryPayload["voximplant"] as? Dictionary<AnyHashable,Any>
        if voximplant != nil {
            self.voxClient.handlePushNotification(payload.dictionaryPayload)
        }
        
        Notify.post(name: Notify.incomingPush)
    }
}
