//
//  VolumeAutomation.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public struct VolumeAutomation {
    
    public var timeRange: CMTimeRange
    
    public var start: Float
    
    public var end: Float
}

public extension VolumeAutomation {
    
    public static func automation(timeRange: CMTimeRange, start: Float, end: Float) -> VolumeAutomation {
        return VolumeAutomation(timeRange: timeRange, start: start, end: end)
    }
}
