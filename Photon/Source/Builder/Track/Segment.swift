//
//  Segment.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 19/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

struct Segment {

    let id: Int
    let assetID: String?
    let scaleFactor: Float64
    let atTime: CMTime
    let timeRange: CMTimeRange
    
    var video: VideoSegment? = nil
    var audio: AudioSegment? = nil
    
    init(id: Int, assetID: String? = nil, scaleFactor: Float64, atTime: CMTime, timeRange: CMTimeRange, video: VideoSegment? = nil, audio: AudioSegment? = nil) {
        self.id = id
        self.assetID = assetID
        self.scaleFactor = scaleFactor
        self.atTime = atTime
        self.timeRange = timeRange
        self.audio = audio
        self.video = video
    }
}

extension Segment {
    
    var headTransitionTimeRange: CMTimeRange {
        guard let video = video, let head = video.headTransition, head.type != .none else {
            return CMTimeRange(start: atTime, duration: kCMTimeZero)
        }
        
        return CMTimeRange(start: atTime, duration: head.duration)
    }
    
    var passthroughTimeRange: CMTimeRange {
        var range = timeRange
        
        // scale
        range.duration = CMTimeMultiplyByFloat64(range.duration, scaleFactor)
        
        // subtract head transition time range
        range.start = atTime + headTransitionTimeRange.duration
        range.duration = range.duration - headTransitionTimeRange.duration
        
        // subtract tail tansition time range
        if let video = video, let tail = video.tailTransition, tail.type != .none {
            range.duration = range.duration - tail.duration
        }
       
        return range
    }
    
    var tailTransitionTimeRange: CMTimeRange {
        let passthrough = passthroughTimeRange
        
        let start = passthrough.start + passthrough.duration
        
        guard let video = video, let tail = video.tailTransition, tail.type != .none else {
            return CMTimeRange(start: start, duration: kCMTimeZero)
        }
        
        return CMTimeRange(start: start, duration: tail.duration)
    }
    
    var insertedTimeRange: CMTimeRange {
        return headTransitionTimeRange.union(passthroughTimeRange).union(tailTransitionTimeRange)
    }
    
    var volumeAutomations: [VolumeAutomation] {
        guard let video = video, let audio = audio, !audio.isMuted else {
            return [VolumeAutomation(timeRange: insertedTimeRange, start: 0.0, end: 0.0)]
        }
        
        var automations: [VolumeAutomation] = []
        
        if let _ = video.headTransition {
            let fadeIn = VolumeAutomation(timeRange: headTransitionTimeRange, start: 0.0, end: audio.volume)
            automations.append(fadeIn)
        }
        
        let passthrough = VolumeAutomation(timeRange: passthroughTimeRange, start: audio.volume, end: audio.volume)
        automations.append(passthrough)
        
        if let _ = video.tailTransition {
            let fadeOut = VolumeAutomation(timeRange: tailTransitionTimeRange, start: audio.volume, end: 0.0)
            automations.append(fadeOut)
        }
        
        return automations
    }
}
