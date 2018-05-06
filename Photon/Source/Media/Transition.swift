//
//  Transition.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 11/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public protocol Transitionable {
    
    var headTransition: VideoTransition { get }
    
    var tailTransition: VideoTransition { get }
}

public protocol MediaTransition {
    
    var timeRange: CMTimeRange { get }
    
    var duration: CMTime { get }
}
