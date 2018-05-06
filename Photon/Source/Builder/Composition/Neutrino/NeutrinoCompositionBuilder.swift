//
//  NeutrinoCompositionBuilder.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct NeutrinoCompositionBuilder : CompositionBuilder {

    func build(with items: [VideoItem]) throws -> NeutrinoComposition {
        
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
        var segments: [Segment] = []
        
        for (index, item) in items.enumerated() {
            let currentIndex = index % 2
            let currentAudioTrack = audioTracks[currentIndex]
            let currentVideoTrack = videoTracks[currentIndex]
            
            let asset = item.asset
            var segment = Segment(id: index, assetID: item.id, scaleFactor: item.scaleFactor, atTime: atTime, timeRange: item.timeRange)
            
            if let audioTrack = asset.tracks(withMediaType: .audio).first {
                hasAudioTrack = true
                try currentAudioTrack.insertTimeRange(item.timeRange, of: audioTrack, at: atTime)
                segment.audio = AudioSegment(atTime: atTime, volume: item.volume, isMuted: item.isMuted)
            }
            
            if let videoTrack = asset.tracks(withMediaType: .video).first {
                try currentVideoTrack.insertTimeRange(item.timeRange, of: videoTrack, at: atTime)
                let trackOrientation = orientation(preferredTransform: videoTrack.preferredTransform)
                segment.video = VideoSegment(orientation: trackOrientation, naturalSize: videoTrack.naturalSize, atTime: atTime, headTransition: item.headTransition, tailTransition: item.tailTransition)
            }
            
            segments.append(segment)
            
            atTime = atTime + item.timeRange.duration
            
            atTime = atTime - item.tailTransition.duration
        }
        
        if !hasAudioTrack {
            for track in audioTracks {
                composition.removeTrack(track)
            }
            
            audioTracks = []
        }
        
        return NeutrinoComposition(composition: composition, videoTracks: videoTracks, audioTracks: audioTracks, segments: segments)
    }
}
