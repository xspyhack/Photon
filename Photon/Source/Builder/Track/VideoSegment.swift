//
//  VideoSegment.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 19/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

struct VideoSegment {
    
    let orientation: UIImageOrientation
    let naturalSize: CGSize
    
    let atTime: CMTime
    
    let headTransition: VideoTransition?
    let tailTransition: VideoTransition?
}
