//
//  CallController.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 06.02.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import Foundation
import UIKit
import VoxImplant

class CallController: UIViewController {

    @IBOutlet weak var localPreview: UIView!
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet weak var callDurationLabel: UILabel!
    @IBOutlet weak var muteVideoButton: UIButton!
    @IBOutlet weak var holdButton: UIButton!
    @IBOutlet weak var receiveVideoButton: UIButton!

    var useCustomCamera: Bool = false
    var call: VICall!
    var timer: Timer?
    var alreadyPoppedUp = false
    var incomingCall: Bool = false
    var videoSend: Bool = false
    var videoReceive: Bool = false
    var devicesAlertSheet: UIAlertController?

    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
//            Log.debug("call duration: \(self.call?.duration())")

            let durationInt = Int(self.call.duration())
            let minutes = durationInt / 60
            let seconds = durationInt % 60

            let text = String.localizedStringWithFormat("%u:%02u", minutes, seconds)

            self.callDurationLabel.text = text
        })

//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.call.sendDTMF("123#")
//        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.devicesAlertSheet != nil) {
            self.devicesAlertSheet!.dismiss(animated: true)
        }
        self.navigationController?.isNavigationBarHidden = false
        timer?.invalidate()
        timer = nil
    }

//    deinit {
//        Log.debug("[CallController:\(String(describing: call.voxCall?.callId))] deinit")
//    }


    override func viewDidLoad() {
        super.viewDidLoad()

        muteVideoButton.isSelected = !self.videoSend
        self.call.add(self)
        self.call.endpoints.first!.delegate = self

        if self.useCustomCamera {
            self.call.videoSource = customCameraSource.customVideoSource
        }
        //self.call.preferredVideoCodec = "H264"

        if self.incomingCall {
            self.call.answer(withSendVideo: self.videoSend, receiveVideo: self.videoReceive, customData: "test custom data", headers: nil)
        } else {
            self.call.start(withHeaders: nil)
        }

        if (self.videoReceive) {
            receiveVideoButton.isHidden = true
        }

        self.localPreview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchCamera)))
        self.remoteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchVideoResizeMode)))

        VIAudioManager.shared().delegate = self
    }

    func switchVideoResizeMode() {

        let switchVideoResizeModeInStreams: ([VIVideoStream]!) -> () = { streams in

            for stream in streams {
                for renderer in stream.renderers {
                    if renderer is VIVideoRendererView {
                        let videoRendererView = renderer as! VIVideoRendererView
                        videoRendererView.resizeMode = videoRendererView.resizeMode == .fill ? .fit : .fill;
                    }
                }
            }
        }

        switchVideoResizeModeInStreams(self.call.localVideoStreams)
        switchVideoResizeModeInStreams(self.call.endpoints.first!.remoteVideoStreams)
    }

    func switchCamera() {
        VICameraManager.shared().useBackCamera = !VICameraManager.shared().useBackCamera
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // test if going to login screen, have to disconnect
        if (self.isMovingFromParentViewController) {
            self.call.hangup(withHeaders: nil)
        }
    }

    func createDevicePicker(show : Bool!) {
        let visible = self.devicesAlertSheet != nil

        if (visible) {
            self.devicesAlertSheet!.dismiss(animated: false)
        }
        if (show || visible) {
            let devices = VIAudioManager.shared().availableAudioDevices();
            self.devicesAlertSheet = UIAlertController(title: "Device", message: nil, preferredStyle: .actionSheet);
            for device in devices! {
                self.devicesAlertSheet!.addAction(UIAlertAction(title: String(describing: device), style: device.type == VIAudioManager.shared().currentAudioDevice().type ? .destructive : .default) { action in
                    VIAudioManager.shared().select(device);
                    self.devicesAlertSheet = nil
                })
            }
            self.present(self.devicesAlertSheet!, animated: !visible, completion: nil)
        }
    }

    internal func callFailedWithError(code: Int32, reason: String) {
        let alertController = UIAlertController(title: "Call Error", message: "Code=\(code) \nReason=\(reason)", preferredStyle: .alert)
        let action = UIAlertAction(title: "Close", style: .destructive) { action in
            self.navigationController!.popViewController(animated: true)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true);
    }

    @IBAction func hangupClick(_ sender: Any) {
        self.call.hangup(withHeaders: nil)
    }

    @IBAction func muteAudioClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.call.sendAudio = !sender.isSelected
    }

    @IBAction func muteVideoClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let enableVideo = !sender.isSelected
        self.call.setSendVideo(enableVideo) { (error) in
            Log.info("sendVideo(\(enableVideo)) : \(String(describing: error))")
        }
    }

    @IBAction func loudClick(_ sender: UIButton) {
        createDevicePicker(show: true)
    }

    @IBAction func holdClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let hold = sender.isSelected
        self.call.setHold(hold) { (error) in
            Log.info("setHold(\(hold)) : \(String(describing: error))")
        }
    }

    @IBAction func receiveVideoClick(_ sender: UIButton) {
        if (self.videoReceive) {
            return
        } else {
            sender.isSelected = !sender.isSelected
            sender.isHidden = true
            self.call.startReceiveVideo(completion: { (error) in
                Log.info("startReceiveVideo: \(String(describing: error))")
            })
        }
    }
}

extension CallController: VICallDelegate {

    func call(_ call: VICall!, didConnectWithHeaders headers: [AnyHashable: Any]!) {
        Log.debug("didConnectWithHeaders: \(headers)")

        call.sendMessage("test message")
        call.sendInfo("test info message", mimeType: "audio/aiff", headers: nil)
    }

    func popup() {
        if (!alreadyPoppedUp) {
            alreadyPoppedUp = true
            self.navigationController?.popViewController(animated: true)
        }
    }

    func call(_ call: VICall!, didDisconnectWithHeaders headers: [AnyHashable: Any]!, answeredElsewhere: NSNumber!) {
        Log.debug("didDisconnectWithHeaders:\(headers) answeredElsewhere=\(answeredElsewhere)")
        popup()
    }

    func call(_ call: VICall!, didAddLocalVideoStream videoStream: VIVideoStream!) {
        let viewRenderer = VIVideoRendererView(containerView: self.localPreview)
        videoStream.addRenderer(viewRenderer)
    }

    func call(_ call: VICall!, didFailWithError error: Error!, headers: [AnyHashable: Any]!) {
        Log.debug("didFailWithError:\(error) headers=\(headers)")
        popup()
    }
}

extension CallController: VIEndpointDelegate {
    func endpoint(_ endpoint: VIEndpoint!, didAddRemoteVideoStream videoStream: VIVideoStream!) {
        let viewRenderer = VIVideoRendererView(containerView: self.remoteView)
        videoStream.addRenderer(viewRenderer)
    }
}

extension CallController: VIAudioManagerDelegate {
    func audioDeviceChanged(_ audioDevice: VIAudioDevice!) {
        createDevicePicker(show: false)
    }

    func audioDeviceUnavailable(_ audioDevice: VIAudioDevice!) {
    }

    func audioDevicesListChanged(_ availableAudioDevices: Set<VIAudioDevice>!) {
        createDevicePicker(show: false)
    }
}

