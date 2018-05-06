//
//  VideoBuilder.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 1/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public struct VideoBuilder {
    
    public var transitionDuration: Float64
    
    public var scaleTransition: Bool = false
    
    public var isMutedWhenVarispeed: Bool = false
    
    public var transitionType: VideoTransitionType = .none
    
    private let transitiomTime: CMTime
    
    public init(transitionDuration: Float64) {
        self.transitionDuration = transitionDuration
        self.transitiomTime = CMTime(value: Int64(transitionDuration * Float64(Defaults.preferredTimescale)), timescale:  Defaults.preferredTimescale)
    }
    
    public func build(videoItems: [VideoItem], completionHandler handler: @escaping (Result<[VideoItem]>) -> Void) {
        
        guard !videoItems.isEmpty else {
            handler(.success(videoItems))
            return
        }

        let group = DispatchGroup()
        for videoItem in videoItems {
            group.enter()
            
            videoItem.isMutedWhenVarispeed = self.isMutedWhenVarispeed
            videoItem.status = .loading
            videoItem.loadValuesAsynchronously { result in
                switch result {
                case .success(let status):
                    videoItem.status = status
                case .failure(let error):
                    videoItem.status = .failed
                    handler(.failure(error))
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.applyTransition(to: videoItems)
            handler(.success(videoItems))
        }
    }
    
    @discardableResult
    public func applyTransition(to videoItems: [VideoItem]) -> Bool {
        
        guard transitionType != .none else {
            return false
        }
        
        for index in Array(0..<videoItems.count) {
            guard let current = videoItems.safe[index] else {
                break
            }
            
            let item = current
            
            if let previous = videoItems.safe[index - 1] {
                item.headTransition = previous.tailTransition
            }
            
            if let next = videoItems.safe[index + 1] {
                let scaledDuration = CMTimeMultiplyByFloat64(current.timeRange.duration, current.scaleFactor)
                let remainder = scaledDuration - current.headTransition.duration
                
                let nextRemainder = CMTimeMultiplyByFloat64(next.timeRange.duration, next.scaleFactor)
                
                if remainder <= transitiomTime || nextRemainder <= transitiomTime {
                    item.tailTransition = .none
                } else {
                    item.tailTransition = videoTransition(scaleFactor: item.scaleFactor)
                }
            }
        }
        
        return true
    }
    
    private func videoTransition(scaleFactor: Float64) -> VideoTransition {
        let duration = scaleTransition ? CMTimeMultiplyByFloat64(transitiomTime, scaleFactor) : transitiomTime
        return VideoTransition(duration: duration, type: transitionType)
    }
}

