//
//  VideoItem.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public class VideoItem : Media, VideoTransitionable {
    
    public let url: URL
    
    public var volume: Float
    
    public let scaleFactor: Float64
    
    public let fillMode: FillMode
    
    public var filter: FilterProtocol?
   
    public var selectedRange: MediaRange? = nil
    
    public var startTime: CMTime
    
    public var timeRange: CMTimeRange
    
    public var isMutedWhenVarispeed: Bool
    
    public let asset: AVAsset
    
    public var id: String {
        return "\(self.hashValue)"
    }
    
    public var type: MediaType {
        return .video
    }
    
    public var status: MediaStatus = .unknown
    
    public var headTransition: VideoTransition
    
    public var tailTransition: VideoTransition
    
    public init(url: URL, volume: Float = 1.0, scaleFactor: Float64 = 1.0, fillMode: FillMode = .aspectFit, filter: FilterProtocol? = nil) {
        self.url = url
        self.volume = volume
        self.asset = AVURLAsset(url: url)
        self.fillMode = fillMode
        self.filter = filter
        self.startTime = kCMTimeZero
        self.timeRange = kCMTimeRangeZero
        self.scaleFactor = scaleFactor
        self.headTransition = .none
        self.tailTransition = .none
        self.isMutedWhenVarispeed = false
    }
}

extension VideoItem {
    
    var isMuted: Bool {
        return isMutedWhenVarispeed && scaleFactor != 1.0
    }

    public func updateTimeRange(_ timeRange: CMTimeRange) {
        self.timeRange = timeRange
    }
}

extension VideoItem : Hashable {
    
    public static func == (lhs: VideoItem, rhs: VideoItem) -> Bool {
        return lhs.url == rhs.url && lhs.timeRange == rhs.timeRange
    }
    
    public var hashValue: Int {
        return self.url.hashValue // fix me
    }
}
