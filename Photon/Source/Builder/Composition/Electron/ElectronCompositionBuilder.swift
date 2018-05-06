//
//  ElectronCompositionBuilder.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct ElectronCompositionBuilder : CompositionBuilder {
    
    var transitionDuration: CMTime = kCMTimeZero
    
    mutating func setTransitionDuration(_ duration: CMTime) -> ElectronCompositionBuilder {
        self.transitionDuration = duration
        return self
    }
    
    func build(with items: [VideoItem]) throws -> ElectronComposition {
        
        let composition = AVMutableComposition()
        
        guard let audioTrackA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw CompositionBuilderError.canNotAddAudioTrack
        }
        
        var audioTracks: [AVMutableCompositionTrack] = [audioTrackA]
        
        if items.count > 1 {
            guard let audioTrackB = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw CompositionBuilderError.canNotAddAudioTrack
            }
            audioTracks.append(audioTrackB)
        }
        
        guard let videoTrackA = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw CompositionBuilderError.canNotAddVideoTrack
        }
        
        var videoTracks: [AVMutableCompositionTrack] = [videoTrackA]
        
        if items.count > 1 {
            guard let videoTrackB = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw CompositionBuilderError.canNotAddVideoTrack
            }
            videoTracks.append(videoTrackB)
        }
        
        var hasAudioTrack = false
        
        var atTime: CMTime = kCMTimeZero

        /// The time range in which the clips should pass through.
        var passthroughTimeRanges: [CMTimeRange] = Array(repeating: kCMTimeRangeZero, count: items.count)
        /// The transition time range for the clips.
        var transitionTimeRanges: [CMTimeRange] = Array(repeating: kCMTimeRangeZero, count: items.count)
        /// The electron for clips.
        var electrons: [Electron] = []
        
        var alternatingIndex = 0
        
        for (index, item) in items.enumerated() {
            alternatingIndex = index % 2 // Alternating targets: 0, 1, 0, 1, ...
            
            let currentAudioTrack = audioTracks[alternatingIndex]
            let currentVideoTrack = videoTracks[alternatingIndex]
            
            let asset = item.asset
            
            var electron = Electron(id: index, assetID: item.id, scaleFactor: item.scaleFactor, atTime: atTime, timeRange: item.timeRange, filter: item.filter)

            if let audioTrack = asset.tracks(withMediaType: .audio).first {
                hasAudioTrack = true
                try currentAudioTrack.insertTimeRange(item.timeRange, of: audioTrack, at: atTime)
                
                electron.hasAudioTrack = true
                electron.volume = item.volume
                electron.isMuted = item.isMuted
                electron.audioTrackID = currentAudioTrack.trackID
            }
            
            if let videoTrack = asset.tracks(withMediaType: .video).first {
                try currentVideoTrack.insertTimeRange(item.timeRange, of: videoTrack, at: atTime)
                
                electron.hasVideoTrack = true
                electron.orientation = orientation(preferredTransform: videoTrack.preferredTransform)
                electron.naturalSize = videoTrack.naturalSize
                electron.videoTrackID = currentVideoTrack.trackID
            }
            
            electrons.append(electron)
            
            passthroughTimeRanges[index] = CMTimeRangeMake(atTime, item.timeRange.duration)
            if index > 0 {
                passthroughTimeRanges[index].start = passthroughTimeRanges[index].start + transitionDuration
                passthroughTimeRanges[index].duration = passthroughTimeRanges[index].duration - transitionDuration
            }
            
            if index + 1 < items.count {
                passthroughTimeRanges[index].duration = passthroughTimeRanges[index].duration - transitionDuration
            }
            
            atTime = atTime + item.timeRange.duration
            atTime = atTime - transitionDuration
            
            if index + 1 < items.count {
                transitionTimeRanges[index] = CMTimeRange(start: atTime, duration: transitionDuration)
            }
        }
        
        if !hasAudioTrack {
            for track in audioTracks {
                composition.removeTrack(track)
            }
            
            audioTracks = []
        }
        
        return ElectronComposition(composition: composition, videoTracks: videoTracks, audioTracks: audioTracks, passthroughTimeRanges: passthroughTimeRanges, transitionTimeRanges: transitionTimeRanges, electrons: electrons)
    }
}
