//
//  ExporterItem.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 16/12/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public struct ExporterItem : Exportable {
   
    public let composition: AVComposition
    
    public let videoComposition: AVVideoComposition
    
    public let audioMix: AVAudioMix
   
    public let filter: FilterProtocol?
    
    public let animationTool: AVVideoCompositionCoreAnimationTool?
    
    public init(composition: AVComposition, videoComposition: AVVideoComposition, audioMix: AVAudioMix, filter: FilterProtocol? = nil, animationTool: AVVideoCompositionCoreAnimationTool? = nil) {
        self.composition = composition
        self.videoComposition = videoComposition
        self.audioMix = audioMix
        self.filter = filter
        self.animationTool = animationTool
    }
}
