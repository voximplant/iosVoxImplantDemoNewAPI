//
//  CallManager.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 21.04.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import UIKit
import VoxImplant
import CallKit

class CallDescriptor {
    
    init(call: VICall, video:Bool, uuid:UUID) {
        self.call = call
        self.video = video
        self.uuid = uuid
    }
    var call:VICall
    var video:Bool
    var uuid:UUID
}


class CallManager: NSObject {

    fileprivate var calls = [UUID:CallDescriptor]()
    
    static var providerConfiguration: CXProviderConfiguration {
        let localizedName = "VoxImplant"
        let providerConfiguration = CXProviderConfiguration(localizedName: localizedName)
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        return providerConfiguration
    }
    
    let voxClient:VIClient
    let provider: CXProvider


    init(voxClient:VIClient) {
        
        self.provider = CXProvider(configuration: type(of: self).providerConfiguration)
        self.voxClient = voxClient
        
        super.init()

        self.voxClient.callManagerDelegate = self
        self.provider.setDelegate(self, queue: DispatchQueue.main)
    }
}


extension CallManager: VIClientCallManagerDelegate {
    
    func client(_ client: VIClient!, didReceiveIncomingCall call: VICall!, withIncomingVideo video: Bool, headers: [AnyHashable : Any]!) {
        Log.debug("didReceiveIncomingCall(\(call)) video=\(video) headers=\(headers)")
        self.reportIncomingCall(call: call, handle: call.endpoints.first!.userDisplayName, hasVideo: video)
    }
}

extension CallManager: VICallDelegate {
    func call(_ call: VICall!, didDisconnectWithHeaders headers: [AnyHashable : Any]!, answeredElsewhere: NSNumber!) {
        Log.debug("didDisconnectWithHeaders:\(headers) answeredElsewhere=\(answeredElsewhere)")
        self.endCall(call:call)
    }
}

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

extension CallManager: CXProviderDelegate {
    
    
    /// Called when the provider has been reset. Delegates must respond to this callback by cleaning up all internal call state (disconnecting communication channels, releasing network resources, etc.). This callback can be treated as a request to end all calls without the need to respond to any actions
    @available(iOS 10.0, *)
    public func providerDidReset(_ provider: CXProvider) {
        Log.debug("CXCall providerDidReset \(provider)")

        VIAudioManager.shared().callKitStopAudio()
    }
    
    private func createCallDescriptor(_ call: VICall, _ hasVideo:Bool) -> CallDescriptor {
        let uuid = UUID();
        let callDescriptor = CallDescriptor(call: call, video: hasVideo, uuid:uuid)
        self.calls[uuid] = callDescriptor
        call.add(self)
        return callDescriptor
    }
    
    
    func endCall(call:VICall) {
        for callDescr in calls.values {
            if callDescr.call == call {
                self.cancelIncomingCall(callDescriptor: callDescr)
            }
        }
    }
    
    func reportOutgoingCall(call: VICall, hasVideo: Bool){
        VIAudioManager.shared().callKitReleaseAudioSession();

        let callDescriptor = createCallDescriptor(call, hasVideo)
        provider.reportOutgoingCall(with: callDescriptor.uuid, startedConnectingAt: Date())
    }
    
    func reportIncomingCall(call: VICall, handle: String, hasVideo: Bool = false) {
        
        let callDescriptor = createCallDescriptor(call,hasVideo)
        // CallKit not avilable on simulator
        if Platform.isSimulator {
            
            // simulator
            Log.info("CXCall incoming call on simulator")
            
            Notify.post(name: Notify.incomingCall, userInfo: ["callDescriptor":callDescriptor])
            
        }else{
            
            
            // Construct a CXCallUpdate describing the incoming call, including the caller.
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: handle)
            update.hasVideo = hasVideo
            

            // Report the incoming call to the system
            provider.reportNewIncomingCall(with: callDescriptor.uuid, update: update) { error in
                if (error != nil) {
                    Log.error("CXCall reportNewIncomingCall error = \(String(describing: error))")
                }

                var audioError:NSError?
                VIAudioManager.shared().callKitConfigureAudioSession(&audioError)
                if (audioError != nil) {
                    Log.error("CXCall reportNewIncomingCall audio error = \(String(describing: audioError))")
                }
            }
        }
    }
    
    func cancelIncomingCall(callDescriptor:CallDescriptor) {
        Log.info("CXCall cancelIncomingCall")
        
        if Platform.isSimulator {
            Notify.post(name: Notify.cancelIncomingCall, userInfo: ["callDescriptor":callDescriptor])
        }else{
            provider.reportCall(with: callDescriptor.uuid, endedAt: Date(), reason: .remoteEnded)
        }
        
        calls.removeValue(forKey: callDescriptor.uuid)
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Log.info("CXCall CXAnswerCallAction")

//        var audioError:NSError?
//        VIAudioManager.shared().callKitConfigureAudioSession(&audioError)
        if let callDescriptor = calls[action.callUUID] {
            
            Notify.post(name: Notify.acceptIncomingCall, userInfo: ["callDescriptor":callDescriptor])
         //   calls.removeValue(forKey: action.callUUID)
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        if let callDescr = calls[action.callUUID] {
            Log.info("CXCall CXPlayDTMFCallAction")
            
            callDescr.call.sendDTMF(action.digits)

            action.fulfill()
        } else {
            action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Log.info("CXCall CXEndCallAction")

        VIAudioManager.shared().callKitStopAudio()
        
        if let callDescr = calls[action.callUUID] {
            calls.removeValue(forKey: action.callUUID)
            if (callDescr.call.duration() > 0) {
                Log.info("CXCall hangup")
                callDescr.call.hangup(withHeaders: nil)
            } else {
                Log.info("CXCall reject")
                callDescr.call.reject(with: .decline, headers: nil)
            }
        }
        provider.reportCall(with: action.callUUID, endedAt: Date(), reason: .declinedElsewhere)
        
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStartAudio()
    }

    func callDisconnected(call: VICall) {
        
    }
}

