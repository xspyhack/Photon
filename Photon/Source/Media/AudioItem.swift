//
//  AudioItem.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public class AudioItem : Media {
    
    public let url: URL
    
    public let asset: AVAsset
    
    public var volume: Float
    
    public let scaleFactor: Float64
    
    public var selectedRange: MediaRange?
    
    public var startTime: CMTime
    
    public var timeRange: CMTimeRange
    
    public var isMutedWhenVarispeed: Bool = false
    
    public var id: String {
        return "todo"
    }
    
    public var type: MediaType {
        return .audio
    }
    
    public var status: MediaStatus = .unknown
    
    public init(url: URL, volume: Float = 1.0, scaleFactor: Float64 = 1.0, isMutedWhenVarispeed: Bool = false) {
        self.url = url
        self.volume = volume
        self.asset = AVURLAsset(url: url)
        self.scaleFactor = scaleFactor
        self.startTime = kCMTimeZero
        self.timeRange = kCMTimeRangeZero
        self.isMutedWhenVarispeed = isMutedWhenVarispeed
    }
}

extension AudioItem {
    
    public func updateTimeRange(_ timeRange: CMTimeRange) {
        self.timeRange = timeRange
    }
}

extension AudioItem : Equatable {
    
    public static func == (lhs: AudioItem, rhs: AudioItem) -> Bool {
        return lhs.url == rhs.url && lhs.timeRange == rhs.timeRange
    }
}
