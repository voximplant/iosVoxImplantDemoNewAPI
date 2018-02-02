/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

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

