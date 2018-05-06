//
//  Exportable.swift
//  Photon
//
//  Created by k on 2017/10/23.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public protocol Exportable {
    
    var composition: AVComposition { get }
    
    var videoComposition: AVVideoComposition { get }
    
    var audioMix: AVAudioMix { get }
    
    var filter: FilterProtocol? { get }
    
    var animationTool: AVVideoCompositionCoreAnimationTool? { get }
}
