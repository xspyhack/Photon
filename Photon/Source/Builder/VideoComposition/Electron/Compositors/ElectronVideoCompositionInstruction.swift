//
//  CustomVideoCompositionInstruction.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

class ElectronVideoCompositionInstruction : NSObject, AVVideoCompositionInstructionProtocol {
    
    /// ID used by subclasses to identify the foreground frame.
    var foregroundTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    /// ID used by subclasses to identify the background frame.
    var backgroundTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    /// For transform, opacity
    var layerInstructions: [ElectronVideoCompositionLayerInstruction] = []
    
    /// The timeRange during which instructions will be effective.
    var overrideTimeRange: CMTimeRange = CMTimeRange()
    /// Indicates whether post-processing should be skipped for the duration of the instruction.
    var overrideEnablePostProcessing = false
    
    /// Indicates whether to avoid some duplicate processing when rendering a frame from the same source and destinatin at different times.
    var overrideContainsTweening = false
    /// The track IDs required to compose frames for the instruction.
    var overrideRequiredSourceTrackIDs: [NSValue]?
    /// Track ID of the source frame when passthrough is in effect.
    var overridePassthroughTrackID: CMPersistentTrackID = 0
    
    /*
     If for the duration of the instruction, the video composition result is one of the source frames, this property
     should return the corresponding track ID. The compositor won't be run for the duration of the instruction and
     the proper source frame will be used instead.
     */
    var passthroughTrackID: CMPersistentTrackID {
        get {
            return self.overridePassthroughTrackID
        }
        set {
            self.overridePassthroughTrackID = newValue
        }
    }
    
    /*
     List of video track IDs required to compose frames for this instruction. If the value of this property
     is nil, all source tracks will be considered required for composition.
     */
    var requiredSourceTrackIDs: [NSValue]? {
        get {
            return self.overrideRequiredSourceTrackIDs
        }
        
        set {
            self.overrideRequiredSourceTrackIDs = newValue
        }
    }
    
    // Indicates the timeRange during which the instruction is effective.
    var timeRange: CMTimeRange {
        get {
            return self.overrideTimeRange
        }
        
        set(newTimeRange) {
            self.overrideTimeRange = newTimeRange
        }
    }
    
    // If NO, indicates that post-processing should be skipped for the duration of this instruction.
    var enablePostProcessing: Bool {
        get {
            return self.overrideEnablePostProcessing
        }
        
        set(newPostProcessing) {
            self.overrideEnablePostProcessing = newPostProcessing
        }
    }
    
    /*
     If YES, rendering a frame from the same source buffers and the same composition instruction at 2 different
     compositionTime may yield different output frames. If NO, 2 such compositions would yield the
     same frame. The media pipeline may me able to avoid some duplicate processing when containsTweening is NO.
     */
    var containsTweening: Bool {
        get {
            return self.overrideContainsTweening
        }
        
        set(newContainsTweening) {
            self.overrideContainsTweening = newContainsTweening
        }
    }
    
    init(passthroughTrackID: CMPersistentTrackID, timeRange: CMTimeRange) {
        super.init()
        
        self.passthroughTrackID = passthroughTrackID
        self.timeRange = timeRange
        
        requiredSourceTrackIDs = [NSValue]()
        containsTweening = false
        enablePostProcessing = false
    }
    
    init(sourceTrackIDs: [NSValue], timeRange: CMTimeRange) {
        super.init()
        
        self.requiredSourceTrackIDs = sourceTrackIDs
        self.timeRange = timeRange
        
        passthroughTrackID = kCMPersistentTrackID_Invalid
        containsTweening = true
        enablePostProcessing = false
    }
}
