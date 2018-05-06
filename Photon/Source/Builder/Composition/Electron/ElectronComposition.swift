//
//  ElectronComposition.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct ElectronComposition : Composition {
    let composition: AVMutableComposition
    let videoTracks: [AVMutableCompositionTrack]
    let audioTracks: [AVMutableCompositionTrack]
    
    var passthroughTimeRanges: [CMTimeRange] = []
    var transitionTimeRanges: [CMTimeRange] = []
    
    var electrons: [Electron] = []
}

extension ElectronComposition {
    
    func volumeAutomations(at index: Int) -> [VolumeAutomation] {
        
        guard !audioTracks.isEmpty else {
            return []
        }
        
        var automations: [VolumeAutomation] = []
        
        for (i, electron) in electrons.enumerated() {
            if index == i % audioTracks.count {
//                let array = electron.volumeAutomations
//                automations.append(contentsOf: array)
            }
        }
        
        return automations
    }
    
    var volumeAutomations: [VolumeAutomation] {
        
        guard !audioTracks.isEmpty else {
            return []
        }
        
//        return segments.flatMap { $0.volumeAutomations }
        return []
    }
}

struct Electron {
    
    let id: Int
    let assetID: String?
    let scaleFactor: Float64
    let atTime: CMTime
    let timeRange: CMTimeRange
    let filter: FilterProtocol?
    
    // For audio type
    var volume: Float = 1.0
    var isMuted: Bool = false
    var hasAudioTrack: Bool = false
    var audioTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

    // For video type
    var hasVideoTrack: Bool = false
    var orientation: UIImageOrientation = .up
    var naturalSize: CGSize = .zero
    var videoTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
}

extension Electron {
    
    init(id: Int, assetID: String?, scaleFactor: Float64, atTime: CMTime, timeRange: CMTimeRange, filter: FilterProtocol? = nil) {
        self.id = id
        self.assetID = assetID
        self.scaleFactor = scaleFactor
        self.atTime = atTime
        self.timeRange = timeRange
        self.filter = filter
    }
}
