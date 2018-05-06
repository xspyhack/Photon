//
//  NeutrinoVideoCompositionInstruction.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct NeutrinoVideoCompositionInstruction {
    
    let compositionInstruction: AVMutableVideoCompositionInstruction
    let fromLayerInstruction: AVMutableVideoCompositionLayerInstruction
    let toLayerInstruction: AVMutableVideoCompositionLayerInstruction
    let transition: VideoTransition
}
