//
//  ElectronVideoCompositionBuilder.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct ElectronVideoCompositionBuilder : VideoCompositionBuilder {
    
    var preferredVideoSize: CGSize = .zero
    
    var fillMode: FillMode = .aspectFill
    
    var compositorClass: AVVideoCompositing.Type?
    
    func build(in composition: ElectronComposition) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition()
        
        guard !composition.electrons.isEmpty else {
            return videoComposition
        }
        
        // Every videoComposition needs these properties to be set:
        videoComposition.frameDuration = preferredFrameDuration

        if preferredVideoSize == .zero {
            // Use the naturalSize of the first video track.
            let videoSize = composition.electrons[0].naturalSize
            videoComposition.renderSize = videoSize
        } else {
            videoComposition.renderSize = preferredVideoSize
        }
        
        videoComposition.customVideoCompositorClass = compositorClass
        
        let instructions = makeTransitionInstructions(in: videoComposition, composition: composition)
        
        // Apply Transform
        
        videoComposition.instructions = instructions

        return videoComposition
    }
 
    private func makeTransitionInstructions(in videoComposition: AVMutableVideoComposition, composition: ElectronComposition) -> [AVVideoCompositionInstructionProtocol] {
        var alternatingIndex = 0
        
        // Set up the video composition to perform cross dissolve or diagonal wipe transitions between clips.
        var instructions = [AVVideoCompositionInstructionProtocol]()
        
        // Cycle between "pass through A", "transition from A to B", "pass through B".
        for i in 0..<composition.electrons.count {
            alternatingIndex = i % 2 // Alternating targets.
            
            let electron = composition.electrons[i]

            if videoComposition.customVideoCompositorClass != nil {
                // 由于需要渲染滤镜，所以这里是没有转场效果就行了，依然不能在合成阶段 pass through
                let videoInstruction = ElectronVideoCompositionInstruction(passthroughTrackID: kCMPersistentTrackID_Invalid, timeRange: composition.passthroughTimeRanges[i])
                videoInstruction.requiredSourceTrackIDs = [composition.videoTracks[alternatingIndex].trackID].map {
                    NSNumber(value: $0)
                }
                
                // TODO: Set transform
                let passthroughLayer = ElectronVideoCompositionLayerInstruction(assetTrack: composition.videoTracks[alternatingIndex], filter: electron.filter?.filter)
            
                videoInstruction.layerInstructions = [passthroughLayer]
                instructions.append(videoInstruction)
            } else {
                // Pass through clip i.
                let passthroughInstruction = AVMutableVideoCompositionInstruction()
                passthroughInstruction.timeRange = composition.passthroughTimeRanges[i]
                let passthroughLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: composition.videoTracks[alternatingIndex])
                passthroughInstruction.layerInstructions = [passthroughLayer]
                instructions.append(passthroughInstruction)
            }

            if i + 1 < composition.electrons.count {
                // Add transition from clip i to clip i+1.
                if videoComposition.customVideoCompositorClass != nil {
                    let sourceTrackIDs = [composition.videoTracks[0].trackID, composition.videoTracks[1].trackID].map { NSNumber(value: $0) }
                    let videoInstruction =
                        ElectronVideoCompositionInstruction(sourceTrackIDs: sourceTrackIDs, timeRange: composition.transitionTimeRanges[i])
                    // First track -> Foreground track while compositing.
                    videoInstruction.foregroundTrackID = composition.videoTracks[alternatingIndex].trackID
                    // Second track -> Background track while compositing.
                    videoInstruction.backgroundTrackID = composition.videoTracks[1 - alternatingIndex].trackID
                    
                    // TODO: Set transform
                    let fromLayer = ElectronVideoCompositionLayerInstruction(assetTrack: composition.videoTracks[alternatingIndex])
                    let toLayer = ElectronVideoCompositionLayerInstruction(assetTrack: composition.videoTracks[1 - alternatingIndex])
                    
                    videoInstruction.layerInstructions = [fromLayer, toLayer]

                    instructions.append(videoInstruction)
                } else {
                    let transitionInstruction = AVMutableVideoCompositionInstruction()
                    transitionInstruction.timeRange = composition.transitionTimeRanges[i]
                    let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: composition.videoTracks[alternatingIndex])
                    let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: composition.videoTracks[1 - alternatingIndex])
                    transitionInstruction.layerInstructions = [fromLayer, toLayer]
                    instructions.append(transitionInstruction)
                }
            }
        }
        
        return instructions
    }
}
