//
//  VideoCompositionInstruction.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 25/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

struct VideoCompositionInstruction {
    
    let compositionInstruction: AVMutableVideoCompositionInstruction
    let fromLayerInstruction: AVMutableVideoCompositionLayerInstruction
    let toLayerInstruction: AVMutableVideoCompositionLayerInstruction
    let transition: VideoTransition
}
