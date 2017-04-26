//
//  LoginTests.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 21.02.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import XCTest
import VoxImplant

let cShortUserName = "test1"
let cUser = "\(cShortUserName)@videochat.allright.voximplant.com"
let cPassword = "testpass"


// store in global variables, because class reinited on each test
fileprivate var accessToken:String?
fileprivate var refreshToken:String?

extension String {
    func md5() -> Data? {
        guard let messageData = self.data(using:String.Encoding.utf8) else { return nil }
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData
    }
    
//    func md5_str(string: String) -> String {
//        return md5()!.map({String(format: "%02hhx", $0)}).joined()
//    }
}

extension Data {
    func hex() -> String{
        return map({String(format: "%02hhx", $0)}).joined()
    }
}

class LoginTests: BaseTests {
    
    var exLoginSuccess:XCTestExpectation?
    var exLoginFailed:XCTestExpectation?
    var exOneTimeKeyGenerated:XCTestExpectation?
    var exRefreshToken:XCTestExpectation?

    var expectedErrorCode:NSNumber?
    var oneTimeKey:String?

    override func setUp() {
        super.setUp()
        self.connect(connectivityCheck: false)
    }
    
    override func tearDown() {
        super.tearDown()
        self.disconnect(ignoreCheck: true)
    }
    
    func loginWithPassword() {
        self.exLoginSuccess = self.expectation(description: "loginWithPassword")
        self.sdk?.login(withUsername: cUser, andPassword: cPassword)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func test_01_LoginWithPassword() {
        self.loginWithPassword()
    }
 
    func test_02_LoginWithToken() {
        self.loginWithPassword()
        self.disconnect()
        self.connect(connectivityCheck: false)
        XCTAssert(accessToken != nil)
        XCTAssert(refreshToken != nil)
        
        self.exLoginSuccess = self.expectation(description: "loginWithToken")
        self.sdk?.login(withUsername: cUser, andToken: accessToken)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func test_03_LoginWithIncorrectPassword() {
        self.exLoginFailed = self.expectation(description: "loginWithIncorrectPassword")
        self.expectedErrorCode = 401
        self.sdk?.login(withUsername: cUser, andPassword: "\(cPassword)incorrectpassword")
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func test_04_LoginWithIncorrectUser() {
        self.exLoginFailed = self.expectation(description: "loginWithIncorrectUser")
        self.expectedErrorCode = 404
        self.sdk?.login(withUsername: "incorrectUser\(cUser)", andPassword: cPassword)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func test_05_loginOneTimeKey() {
        self.exOneTimeKeyGenerated = self.expectation(description: "oneTimeKeyGenerated")
        self.sdk?.requestOneTimeKey(withUsername: cUser)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
        XCTAssert(self.oneTimeKey != nil)
        
        let md5_user_pass = "\(cShortUserName):voximplant.com:\(cPassword)".md5()?.hex()
        let md5 = "\(self.oneTimeKey!)|\(md5_user_pass!)".md5()?.hex()
        
        self.exLoginSuccess = self.expectation(description: "loginOneTimeKey")
        self.sdk?.login(withUsername: cUser, andOneTimeKey: md5)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func test_06_loginWithIncorrectOneTimeKey() {
        self.exOneTimeKeyGenerated = self.expectation(description: "oneTimeKeyGenerated")
        self.sdk?.requestOneTimeKey(withUsername: cUser)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
        XCTAssert(self.oneTimeKey != nil)
        
        let md5_user_pass = "\(cShortUserName):voximplant.com:\(cPassword)".md5()?.hex()
        let md5 = "\(self.oneTimeKey!)incorrect|\(md5_user_pass!)".md5()?.hex()
        
        self.exLoginFailed = self.expectation(description: "loginIncorrectOneTimeKey")
        self.expectedErrorCode = 401
        self.sdk?.login(withUsername: cUser, andOneTimeKey: md5)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func test_07_RefreshToken() {
        self.loginWithPassword()
        self.disconnect()
        self.connect(connectivityCheck: false)
        XCTAssert(accessToken != nil)
        XCTAssert(refreshToken != nil)
        
        self.exRefreshToken = self.expectation(description: "refreshToken")
        self.sdk?.refreshToken(withUsername: cUser, andToken: refreshToken)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
        XCTAssert(accessToken != nil)
        XCTAssert(refreshToken != nil)
        
        // connect with new accessToken
        self.exLoginSuccess = self.expectation(description: "loginWithNewAccessToken")
        self.sdk?.login(withUsername: cUser, andToken: accessToken)
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func test_07_IncorrectRefreshToken() {
        self.loginWithPassword()
        self.disconnect()
        self.connect(connectivityCheck: false)
        XCTAssert(accessToken != nil)
        XCTAssert(refreshToken != nil)
        
        self.exRefreshToken = self.expectation(description: "refreshToken")
        self.expectedErrorCode = 701
        self.sdk?.refreshToken(withUsername: cUser, andToken: "\(refreshToken)incorrect")
        self.waitForExpectations(timeout: cExpectationsWaitTimeout, handler: nil)
    }
    
    func onLoginSuccessful(withDisplayName displayName: String!, andAuthParams authParams: [AnyHashable : Any]!) {
        
        accessToken = authParams["accessToken"] as? String
        refreshToken = authParams["refreshToken"] as? String
        self.exLoginSuccess?.fulfill()
    }
    
    func onLoginFailedWithErrorCode(_ errorCode: NSNumber!) {
        if let _expectedErrorCode = self.expectedErrorCode {
            XCTAssertEqual(_expectedErrorCode, errorCode)
        }
        self.exLoginFailed?.fulfill()
    }
    
    func onOneTimeKeyGenerated(_ key: String!) {
        self.oneTimeKey = key
        self.exOneTimeKeyGenerated?.fulfill()
    }
    
    func onRefreshTokenSuccess(_ authParams: [AnyHashable : Any]!) {
        accessToken = authParams["accessToken"] as? String
        refreshToken = authParams["refreshToken"] as? String
        self.exRefreshToken?.fulfill()
    }
    
    func onRefreshTokenFailed(_ errorCode: NSNumber!) {
        XCTAssertEqual(self.expectedErrorCode, errorCode)
        self.exRefreshToken?.fulfill()
    }
}

