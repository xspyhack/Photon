//
//  CMTime+Photon.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 23/12/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import CoreMedia

// MARK: - Debugging

extension CMTime : CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return "\(seconds)"
    }
    
    public var debugDescription: String {
        return String(describing: CMTimeCopyDescription(nil, self))
    }
}

extension CMTimeRange : CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return "{\(start.value)/\(start.timescale) = \(Float(start.value) / Float(start.timescale)), \(duration.value)/\(duration.timescale) = \(Float(duration.value) / Float(duration.timescale))}"
    }
    
    public var debugDescription: String {
        return "{start:\(start), duration:\(duration)}"
    }
}

