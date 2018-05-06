//
//  MediaRange.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import CoreMedia

public struct MediaRange {
    
    public let start: Float64
    
    public let duration: Float64
    
    public init(start: Float64, duration: Float64) {
        self.start = start
        self.duration = duration
    }
    
    public static func range(start: Float64, duration: Float64) -> MediaRange {
        return MediaRange(start: start, duration: duration)
    }
}

extension MediaRange {
    
    public init(start: Float64, end: Float64) {
        let duration = end - start
        self.init(start: start, duration: duration)
    }
    
    public var isValid: Bool {
        return start >= 0 && duration >= 0
    }
    
    public var isEmpty: Bool {
        return duration == 0
    }
    
    public var end: Float64 {
        return start + duration
    }
    
    public func union(_ otherRange: MediaRange) -> MediaRange {
        let start = min(self.start, otherRange.start)
        let end = max(self.end, otherRange.end)
        return MediaRange(start: start, end: end)
    }
    
    public func intersection(_ otherRange: MediaRange) -> MediaRange {
        let start = max(self.start, otherRange.start)
        let end = min(self.end, otherRange.end)
        return MediaRange(start: start, end: end)
    }
    
    public func containsTime(_ time: Float64) -> Bool {
        return time >= start && time <= end
    }
    
    public func containsRange(_ range: MediaRange) -> Bool {
        return start <= range.start && end >= range.end
    }
}

extension MediaRange : Equatable {
    
    public static func == (lhs: MediaRange, rhs: MediaRange) -> Bool {
        return lhs.start == rhs.start && lhs.duration == rhs.duration
    }
}
