//
//  VIController.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 20.04.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import UIKit
import VoxImplant

class VIController: NSObject {

    let voxClient:VIClient
    var voxCallManager:CallManager
    
    override init() {
        
        VIClient.setLogLevel(.info)
        self.voxClient = VIClient(delegateQueue: DispatchQueue.main)
        self.voxCallManager = CallManager(voxClient: self.voxClient)

        super.init()

        self.voxClient.sessionDelegate = self
        
        registerForPushNotifications()
    }
    
    fileprivate var user:String!
    fileprivate var password:String!
    fileprivate var gateway:String?
    fileprivate var loginSuccess:VILoginSuccess!
    fileprivate var loginFailure:VILoginFailure!
    
    func login(user:String,
               password:String,
               gateway:String?,
               success: @escaping VILoginSuccess,
               failure: @escaping VILoginFailure) {
        
        self.user = user;
        self.password = password
        self.gateway = gateway
        self.loginSuccess = success;
        self.loginFailure = failure;
        
        if let gate = gateway, gate.characters.count > 0 {
            self.voxClient.connect(withConnectivityCheck: false, gateways: [gate])
        }else {
            self.voxClient.connect()
        }
    }
    
    func disconnect() {
        self.voxClient.disconnect()
    }
    
    func outgoingCall(user:String) -> VICall {
        return self.voxClient.call(toUser: user, customData: "VoxImplant Demo Custom Data")
    }
}

extension VIController : VIClientSessionDelegate {

    func client(_ client: VIClient!, sessionDidFailConnectWithError error: Error!) {
        Log.debug("sessionDidFailConnectWithError: \(error)")
        self.loginFailure(error)
    }
    
    func clientSessionDidDisconnect(_ client: VIClient!) {
        Log.debug("clientSessionDidDisconnect")
        Notify.post(name: Notify.disconnected)
    }
    
    func clientSessionDidConnect(_ client: VIClient!) {
        Log.debug("clientSessionDidConnect")
        self.voxClient.login(withUser: self.user,
                             password: self.password,
                             success: self.loginSuccess,
                             failure: self.loginFailure)
    }
}