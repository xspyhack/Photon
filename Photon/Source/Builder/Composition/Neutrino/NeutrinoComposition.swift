//
//  NeutrinoComposition.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct NeutrinoComposition : Composition {
    let composition: AVMutableComposition
    let videoTracks: [AVMutableCompositionTrack]
    let audioTracks: [AVMutableCompositionTrack]
    
    var segments: [Segment]
}

extension NeutrinoComposition {
    
    func volumeAutomations(at index: Int) -> [VolumeAutomation] {
        
        guard !audioTracks.isEmpty else {
            return []
        }
        
        var automations: [VolumeAutomation] = []
        
        for (i, segment) in segments.enumerated() {
            if index == i % audioTracks.count {
                let array = segment.volumeAutomations
                automations.append(contentsOf: array)
            }
        }
        
        return automations
    }
    
    var volumeAutomations: [VolumeAutomation] {
        
        guard !audioTracks.isEmpty else {
            return []
        }
        
        return segments.flatMap { $0.volumeAutomations }
    }
}
