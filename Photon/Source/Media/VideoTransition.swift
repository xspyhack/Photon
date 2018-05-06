//
//  VideoTransition.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

protocol VideoTransitionable {
    
    var headTransition: VideoTransition { get }
    
    var tailTransition: VideoTransition { get }
}

extension VideoTransitionable {
    
    var headTransition: VideoTransition {
        return VideoTransition.none
    }
    
    var tailTransition: VideoTransition {
        return VideoTransition.none
    }
}

public enum VideoTransitionType {
    case none
    case fade
    case dissolve
}

public struct VideoTransition : MediaTransition {
    
    public var timeRange: CMTimeRange = kCMTimeRangeZero
    
    public var duration: CMTime
    
    public var type: VideoTransitionType
}

public extension VideoTransition {
    
    public static let none = VideoTransition(duration: kCMTimeZero, type: .none)
    
    public init(duration: CMTime, type: VideoTransitionType) {
        self.init(timeRange: kCMTimeRangeZero, duration: duration, type: type)
    }
    
    public static func dissolve(duration: CMTime) -> VideoTransition {
        return VideoTransition(duration: duration, type: .dissolve)
    }
    
    public static func fade(duration: CMTime) -> VideoTransition {
        return VideoTransition(duration: duration, type: .fade)
    }
}
