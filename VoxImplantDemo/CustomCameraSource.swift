/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

class CustomCameraSource: NSObject {

    public let customVideoSource:VICustomVideoSource
    var count = 0

    override init() {
        
        customVideoSource = VICustomVideoSource(videoFormats: [VIVideoFormat(frame:CGSize(width:640,height:480),fps:30)])
        super.init()
        customVideoSource.delegate = self
        
    }
}


extension CustomCameraSource: VICustomVideoSourceDelegate {
    
    func start(with format: VIVideoFormat!) {
        Log.info("CustomCameraSource:Start with format: \(format)")
        
        
        processNextFrame();
    }
    
    func processNextFrame() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.033333333) { 


            var pixelBufferOpt:CVPixelBuffer?
            CVPixelBufferCreate(nil, 480, 640, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, nil, &pixelBufferOpt)
            
            if let pixelBuffer = pixelBufferOpt {
                
                CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                if let baseAddr = CVPixelBufferGetBaseAddress(pixelBuffer) {

                    memset(baseAddr,0x7FFFFFFF,462728)

                    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                }
                self.customVideoSource.sendVideoFrame(pixelBuffer, rotation: VIRotation._90)
                self.processNextFrame()
            }
          }

    }
    
    func stop() {
        Log.info("CustomCameraSource:Stop")
    }
}
