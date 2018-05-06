//
//  AudioMixBuilder.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 19/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

struct AudioMixBuilder {
    
    var audioMix: AVMutableAudioMix = AVMutableAudioMix()
    
    func build(in composition: Composition) {
        guard !composition.audioTracks.isEmpty else {
            return
        }
        
        for (index, track) in composition.audioTracks.enumerated() {
            add(audioTrack: track, with: composition.volumeAutomations(at: index))
        }
    }
    
    @discardableResult
    func add(audioTrack: AVCompositionTrack, with volumeAutomations: [VolumeAutomation]) -> CMPersistentTrackID {
        
        let parameters = AVMutableAudioMixInputParameters(track: audioTrack)
        
        set(volumeAutomations: volumeAutomations, to: parameters)
        
        var inputParameters: [AVAudioMixInputParameters] = []
        
        if !audioMix.inputParameters.isEmpty {
            inputParameters.append(contentsOf: audioMix.inputParameters)
        }
        
        inputParameters.append(parameters)
        audioMix.inputParameters = inputParameters
        
        return parameters.trackID
    }
    
    func set(volumeAutomations: [VolumeAutomation], to inputParameters: AVMutableAudioMixInputParameters) {
        
        for automation in volumeAutomations {
            var startVolume: Float = 1.0
            var endVolume: Float = 1.0
            var timeRange = kCMTimeRangeZero
            
            let success = inputParameters.getVolumeRamp(for: automation.timeRange.start, startVolume: &startVolume, endVolume: &endVolume, timeRange: &timeRange)
            
            if success, !automation.timeRange.intersection(timeRange).isEmpty {
                print("Can't overlay volume ramp")
                print(timeRange)
                continue
            }
            
            inputParameters.setVolumeRamp(fromStartVolume: automation.start, toEndVolume: automation.end, timeRange: automation.timeRange)
        }
    }
}

