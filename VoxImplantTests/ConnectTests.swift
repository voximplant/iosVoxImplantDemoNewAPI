//
//  VoxImplantTests.swift
//  VoxImplantTests
//
//  Created by Andrey Syvrachev on 21.02.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import XCTest
import VoxImplant


class ConnectTests: BaseTests {
        
    func test_01_Connect() {
        self.connect(connectivityCheck: false)
    }
    
    func test_02_Disconnect(){
        self.disconnect()
    }
    
    func test_03_ConnectWithConnectivityCheck() {
        self.connect(connectivityCheck: true)
    }
    
    func test_04_Disconnect(){
        self.disconnect()
    }
}

