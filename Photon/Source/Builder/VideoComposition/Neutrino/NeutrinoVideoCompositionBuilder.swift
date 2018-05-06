//
//  NeutrinoVideoCompositionBuilder.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

struct NeutrinoVideoCompositionBuilder {
    
    var preferredVideoSize: CGSize = .zero
    
    var fillMode: FillMode = .aspectFill
    
    var videoComposition: AVMutableVideoComposition? = nil
    
    func build(in composition: NeutrinoComposition) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition.composition)
        
        let videoSegments = composition.segments.map { $0.video! }
        let instructions = makeInstructions(in: videoComposition, videoSegments: videoSegments)
        
        // Apply Transition
        applyTransition(to: instructions)
        
        // Apply Transform
        applyTransform(to: videoComposition, videoSegments: videoSegments)
        
        return videoComposition
    }
    
    private func makeInstructions(in videoComposition: AVMutableVideoComposition, videoSegments: [VideoSegment] = []) -> [VideoCompositionInstruction] {
        
        var transitionInstructions: [VideoCompositionInstruction] = []
        
        var layerInstructionIndex = 1
        
        var isTransitioningLayer = true
        
        var index = 0
        
        for instruction in videoComposition.instructions {
            guard let instruction = instruction as? AVMutableVideoCompositionInstruction else {
                break
            }
            
            if instruction.layerInstructions.count > 1 {
                let fromLayerInstruction = instruction.layerInstructions[1 - layerInstructionIndex] as! AVMutableVideoCompositionLayerInstruction
                let toLayerInstruction = instruction.layerInstructions[layerInstructionIndex] as! AVMutableVideoCompositionLayerInstruction
                let transition = videoSegments[index - 1].tailTransition
                let transitionInstruction = VideoCompositionInstruction(compositionInstruction: instruction, fromLayerInstruction: fromLayerInstruction, toLayerInstruction: toLayerInstruction, transition: transition!)
                
                transitionInstructions.append(transitionInstruction)
                layerInstructionIndex = layerInstructionIndex == 1 ? 0 : 1
            } else {
                if !isTransitioningLayer {
                    layerInstructionIndex = layerInstructionIndex == 1 ? 0 : 1
                }
                
                index += 1
            }
            
            isTransitioningLayer = instruction.layerInstructions.count > 1
        }
        
        return transitionInstructions
    }
    
    private func applyTransition(to instructions: [VideoCompositionInstruction]) {
        
        for instruction in instructions {
            let timeRange = instruction.compositionInstruction.timeRange
            let fromLayer = instruction.fromLayerInstruction
            let toLayer = instruction.toLayerInstruction
            
            switch instruction.transition.type {
            case .fade:
                fromLayer.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: timeRange)
                toLayer.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: timeRange)
            case .dissolve:
                fromLayer.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: timeRange)
            case .none:
                ()
            }
            
            instruction.compositionInstruction.layerInstructions = [fromLayer, toLayer]
        }
    }
    
    func applyTransform(to videoComposition: AVMutableVideoComposition, videoSegments segments: [VideoSegment]) {
        var renderSize = preferredVideoSize
        var index = 0
        
        for instruction in videoComposition.instructions {
            guard let instruction = instruction as? AVMutableVideoCompositionInstruction, !instruction.layerInstructions.isEmpty else {
                break
            }
            
            if instruction.layerInstructions.count == 1 {
                let segment = segments[index]
                let orientation = segment.orientation
                let naturalSize = segment.naturalSize
                
                // final output size
                if renderSize == .zero {
                    renderSize = orientation == .up || orientation == .down ? CGSize(width: naturalSize.height, height: naturalSize.width) : naturalSize
                }
                
                let layerInstruction = instruction.layerInstructions[0] as! AVMutableVideoCompositionLayerInstruction
                let layerTransform = transform(withOrientation: orientation, renderSize: renderSize, naturalSize: naturalSize, fillMode: fillMode)
                
                // passthrough: insert time + transition duration
                let atTime = segment.atTime + segment.headTransition!.duration
                
                layerInstruction.setTransform(layerTransform, at: atTime)
                
                index += 1
            } else {
                let fromSegment = segments[index - 1]
                let toSegment = segments[index]
                
                let atTime = toSegment.atTime
                
                let fromLayerInstruction = instruction.layerInstructions[0] as! AVMutableVideoCompositionLayerInstruction
                let fromTransform = transform(withOrientation: fromSegment.orientation, renderSize: renderSize, naturalSize: fromSegment.naturalSize, fillMode: fillMode)
                fromLayerInstruction.setTransform(fromTransform, at: atTime)
                
                let toLayerInstruction = instruction.layerInstructions[1] as! AVMutableVideoCompositionLayerInstruction
                let toTransform = transform(withOrientation: toSegment.orientation, renderSize: renderSize, naturalSize: toSegment.naturalSize, fillMode: fillMode)
                toLayerInstruction.setTransform(toTransform, at: atTime)
            }
        }
        
        videoComposition.renderSize = renderSize
    }
}
