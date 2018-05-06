//
//  Media.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public enum MediaType {
    case video
    case audio
}

public enum MediaStatus {
    case unknown
    case loading
    case loaded
    case failed
}

public protocol Media : Timeline, Scalable {
    
    var asset: AVAsset { get }
    
    var id: String { get }
    
    var volume: Float { get set }
    
    var selectedRange: MediaRange? { get }

    var type: MediaType { get }
    
    var status: MediaStatus { get set }
    
    var isMutedWhenVarispeed: Bool { get set }
    
    func loadValuesAsynchronously(handler: @escaping (Result<MediaStatus>) -> Void)
    
    func updateTimeRange(_ timeRange: CMTimeRange)
}

extension Media {
    
    public func loadValuesAsynchronously(handler: @escaping (Result<MediaStatus>) -> Void) {
        asset.loadValuesAsynchronously(forKeys: [Photon.Value.duration.key, Photon.Value.tracks.key]) {
            var error: NSError? = nil
            
            guard self.asset.statusOfValue(forKey: Photon.Value.duration.key, error: &error) == .loaded, self.asset.statusOfValue(forKey: Photon.Value.tracks.key, error: &error) == .loaded else {
                handler(.failure(error ?? PhotonError.unknown))
                return
            }
            
            if let selectedRange = self.selectedRange, selectedRange.start != 0.0 || selectedRange.duration != 0.0 {
                let start = CMTime(seconds: selectedRange.start, preferredTimescale: self.asset.duration.timescale)
                let duration = CMTime(seconds: selectedRange.duration, preferredTimescale: self.asset.duration.timescale)
                let timeRange = CMTimeRange(start: start, duration: duration)
                
                self.updateTimeRange(timeRange)
            } else {
                let timeRange = CMTimeRange(start: kCMTimeZero, duration: self.asset.duration)
                
                self.updateTimeRange(timeRange)
            }
            
            handler(.success(.loaded))
        }
    }
}
