//
//  Composition.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 19/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

protocol Composition {
    var composition: AVMutableComposition { get }
    var videoTracks: [AVMutableCompositionTrack] { get }
    var audioTracks: [AVMutableCompositionTrack] { get }
    
    func volumeAutomations(at index: Int) -> [VolumeAutomation]
}

extension Composition {
    func volumeAutomations(at index: Int) -> [VolumeAutomation] {
        return []
    }
}
