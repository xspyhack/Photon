//
//  PlayerView.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 29/10/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import UIKit
import AVFoundation

public class PlayerView: UIView {
    
    var videoLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }
    
    private var videoInfo: CMVideoFormatDescription?
    
    public override class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }
    
    func display(pixelBuffer: CVPixelBuffer, atTime outputTime: CMTime) {
        var err: OSStatus = noErr
        
        if videoInfo == nil || !CMVideoFormatDescriptionMatchesImageBuffer(videoInfo!, pixelBuffer) {
            videoInfo = nil
         
            err = CMVideoFormatDescriptionCreateForImageBuffer(nil, pixelBuffer, &videoInfo)
            if (err != noErr) {
                print("Error at CMVideoFormatDescriptionCreateForImageBuffer \(err)")
            }
        }
        
        guard let info = videoInfo else {
            return
        }
        
        var sampleTimingInfo = CMSampleTimingInfo(duration: kCMTimeInvalid, presentationTimeStamp: outputTime, decodeTimeStamp: kCMTimeInvalid)
        var sampleBuffer: CMSampleBuffer?
        
        err = CMSampleBufferCreateForImageBuffer(nil, pixelBuffer, true, nil, nil, info, &sampleTimingInfo, &sampleBuffer)
        if (err != noErr) {
            print("Error at CMSampleBufferCreateForImageBuffer \(err)")
        }
        
        guard let buffer = sampleBuffer, videoLayer.isReadyForMoreMediaData else {
            return
        }
        
        videoLayer.enqueue(buffer)
    }
}
