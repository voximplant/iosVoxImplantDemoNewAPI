/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

class CameraPreprocessor: NSObject {
    let cameraManager = VICameraManager.shared()
   // var count = 0

    override init() {
        super.init()
        cameraManager?.videoPreprocessDelegate = self
    }

}

extension CameraPreprocessor: VIVideoPreprocessDelegate {


    func preprocessVideoFrame(_ pixelBuffer: CVPixelBuffer!, rotation: VIRotation) {
        //Log.info("onPreprocessCameraCapturedVideo: rotation=\(rotation)")
        if (pixelBuffer == nil) {
            return
        }
        
        let size = CVPixelBufferGetDataSize(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        if let baseAddr = CVPixelBufferGetBaseAddress(pixelBuffer) {
     //       let data = Data(bytes: baseAddr, count: size)
            
            
//            DispatchQueue.global().async {
//                let fileUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("video_frame_\(self.count).raw")
//                do {
//                    try data.write(to: fileUrl)
//                }catch {
//                    Log.error("Error writing to file: \(String(describing: fileUrl))")
//                }
//            }
//
//            self.count = self.count + 1
            
            memset(baseAddr, 300, size/3)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        

    }
    
}
