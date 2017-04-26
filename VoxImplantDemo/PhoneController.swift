//
//  PhoneController.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 06.02.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import Foundation
import UIKit
import VoxImplant

class PhoneController: UIViewController {
    
    @IBOutlet weak var destUser: UITextField!
    @IBOutlet weak var videoCallButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(disconnected), name: Notify.disconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(incomingCall(notification:)), name: Notify.incomingCall, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelIncomingCall(notification:)), name: Notify.cancelIncomingCall, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(acceptIncomingCall(notification:)), name: Notify.acceptIncomingCall, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rejectIncomingCall(notification:)), name: Notify.rejectIncomingCall, object: nil)
    }

    @IBAction func userNameChanged(_ textField: UITextField) {
        testUserNameTextField()
    }
    
    private func testUserNameTextField(){
        let enable = (destUser.text?.characters.count)! > 0
        callButton.isEnabled = enable
        videoCallButton.isEnabled = enable
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserDefaults()
        testUserNameTextField()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notify.disconnected, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notify.incomingCall, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notify.cancelIncomingCall, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notify.acceptIncomingCall, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notify.rejectIncomingCall, object: nil)
    }
    
    private func loadUserDefaults(){
        let defaults = UserDefaults.standard
        defaults.synchronize()
        destUser.text = defaults.string(forKey: "destUser")
    }
    
    private func saveUserDefaults(){
        let defaults = UserDefaults.standard
        defaults.setValue(destUser.text, forKey: "destUser")
    }
    
    func disconnected(){
        Log.debug("disconnected")
        self.navigationController!.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if vox.isDisconnected {
//            self.navigationController!.popToRootViewController(animated: true)
//        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveUserDefaults()

        // test if going to login screen, have to disconnect
        if (self.isMovingFromParentViewController) {
            voxController.disconnect()
        }
    }
    
    func createCallController() -> CallController {
        return self.storyboard?.instantiateViewController(withIdentifier: "CallController") as! CallController
    }
    
    
    private func startOutgoingCall(video:Bool) {
        let callController = createCallController()
        callController.call = voxController.outgoingCall(user: self.destUser.text!)
        callController.video = video
        voxController.voxCallManager.reportOutgoingCall(call: callController.call, hasVideo: video)
        self.navigationController?.pushViewController(callController, animated: true)
    }
    
    @IBAction func videoCallClick(_ sender: Any) {
        self.startOutgoingCall(video: true)
    }
    
    @IBAction func callClick(_ sender: Any) {
        self.startOutgoingCall(video: false)
    }
    
    var incomingAlertController:UIAlertController?
    
    // this function used on simulator only, because CallKit on simulator not working
    func incomingCall(notification:Notification) {
        
        let callDescriptor = notification.userInfo!["callDescriptor"] as! CallDescriptor
        let from = callDescriptor.call.endPoints.first!.userDisplayName
        
        let videoStr = callDescriptor.video ? "Video ":""
        
        incomingAlertController = UIAlertController(title: "Incoming \(videoStr)Call", message: from, preferredStyle: .actionSheet)
        
        let actionAccept = UIAlertAction(title: "Accept", style: .default) { action in
            Notify.post(name: Notify.acceptIncomingCall, userInfo:["callDescriptor":callDescriptor])
        }
        incomingAlertController!.addAction(actionAccept)
        
        let actionDecline = UIAlertAction(title: "Decline", style: .cancel) { action in
            Notify.post(name: Notify.rejectIncomingCall, userInfo: ["callDescriptor":callDescriptor])
        }
        incomingAlertController!.addAction(actionDecline)
        self.present(incomingAlertController!, animated: true);
    }
    
    func cancelIncomingCall(notification:Notification) {
        incomingAlertController?.dismiss(animated: true, completion: nil)
    }
    
    func acceptIncomingCall(notification:Notification) {

        let callDescriptor = notification.userInfo!["callDescriptor"] as! CallDescriptor
        let callController = self.createCallController()
        callController.video = callDescriptor.video
        callController.call = callDescriptor.call
        self.navigationController?.pushViewController(callController, animated: true)
    }
    
    func rejectIncomingCall(notification:Notification) {
        let callDescriptor = notification.userInfo!["callDescriptor"] as! CallDescriptor
        callDescriptor.call.stop(withHeaders: nil)
    }
}
