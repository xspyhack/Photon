//
//  PreviewerItem.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 12/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public struct PreviewerItem : Previewable {
    
    public let composition: AVComposition
    
    public let videoComposition: AVVideoComposition
    
    public let audioMix: AVAudioMix
    
    public let filter: FilterProtocol?
    
    public let overlayLayer: CALayer?
    
    public init(composition: AVComposition, videoComposition: AVVideoComposition, audioMix: AVAudioMix, filter: FilterProtocol? = nil, overlayLayer: CALayer? = nil) {
        self.composition = composition
        self.videoComposition = videoComposition
        self.audioMix = audioMix
        self.filter = filter
        self.overlayLayer = overlayLayer
    }
}
