//
//  ElectronVideoCompositionLayerInstruction.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 27/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct ElectronVideoCompositionLayerInstruction {
    
    let trackID: CMPersistentTrackID
    let tranform: CGAffineTransform
    
    let filter: CIFilter?
    
    let opacity: Float
    
    init(assetTrack: AVAssetTrack, filter: CIFilter? = nil) {
        self.trackID = assetTrack.trackID
        self.tranform = assetTrack.preferredTransform
        self.opacity = 1.0
        self.filter = filter
    }
}
