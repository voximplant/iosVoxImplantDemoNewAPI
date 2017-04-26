//
//  BaseTests.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 21.02.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import XCTest
import VoxImplant

let cExpectationsWaitTimeout = 20.0

func voximplantInit() -> VoxImplant!{
    VoxImplant.setLogLevel(DEBUG_LOG_LEVEL)
    return VoxImplant.getInstance()
}

class BaseTests: XCTestCase {
    
    let sdk = voximplantInit()
    
    var exConnext:XCTestExpectation?
    var exDisconnect:XCTestExpectation?
    
    var error:String?
    
    override func setUp() {
        super.setUp()
        self.sdk?.voxDelegate = self;
    }
    
    func connect(connectivityCheck:Bool){
        self.exConnext = self.expectation(description: "connect")
        self.sdk?.connect(connectivityCheck)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
        XCTAssert(error == nil, error!)
    }
    
    func disconnect() {
        self.disconnect(ignoreCheck: true)
    }
    func disconnect(ignoreCheck:Bool){
        if (!ignoreCheck){
            self.exDisconnect = self.expectation(description: "disconnect")
        }
        self.sdk?.closeConnection()
        if (!ignoreCheck){
            self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
        }
    }
    
}

extension BaseTests: VoxImplantDelegate {
    
    func onConnectionSuccessful() {
        self.exConnext?.fulfill()
    }
    
    func onConnectionClosed() {
        self.exDisconnect?.fulfill()
    }
    
    func onConnectionFailedWithError(_ reason: String!) {
        self.error = reason
        self.exConnext?.fulfill()

    }
}
