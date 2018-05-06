//
//  AVAsset+Photon.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 06/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

extension Photon where Base: AVAsset {
    
    public enum Value: String {
        case tracks
        case duration
        case playable
        case composable
        case readable
        case exportable
        
        var key: String {
            return rawValue
        }
        
        func isLoaded(for asset: AVAsset) -> Bool {
            return asset.statusOfValue(forKey: key, error: nil) == .loaded
        }
    }
    
    public enum Track {
        case video
        case audio
        
        var mediaType: AVMediaType {
            switch self {
            case .video:
                return .video
            case .audio:
                return .audio
            }
        }
    }
}

extension Photon where Base: AVAsset {
    
    public var isDurationLoaded: Bool {
        return base.statusOfValue(forKey: Value.duration.key, error: nil) == .loaded
    }
    
    public var isTracksLoaded: Bool {
        return base.statusOfValue(forKey: Value.tracks.key, error: nil) == .loaded
    }
    
    public var isPlayableLoaded: Bool {
        return base.statusOfValue(forKey: Value.playable.key, error: nil) == .loaded
    }
    
    public var video: AVAsset? {
        do {
            let mixComposition = AVMutableComposition()
            try mixComposition.ph.add(.video, from: base)
            return mixComposition
        } catch {
            return nil
        }
    }
    
    public var audio: AVAsset? {
        do {
            let mixComposition = AVMutableComposition()
            try mixComposition.ph.add(.audio, from: base)
            return mixComposition
        } catch {
            return nil
        }
    }
    
    public func tracks(_ type: Track) throws -> [AVAssetTrack] {
        guard load(values: [.duration, .tracks]) else {
            throw PhotonError.invalidFormat
        }
        
        return base.tracks(withMediaType: type.mediaType)
    }
    
    public var naturalSize: CGSize {
        guard let videoTrack = (try? tracks(.video))?.first else {
            return CGSize.zero
        }
        
        var isVideoAssetPortrait = false
        let videoTransform = videoTrack.preferredTransform
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        
        var naturalSize = videoTrack.naturalSize
        if isVideoAssetPortrait {
            naturalSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        }
        
        return naturalSize
    }
    
    public var frames: [CMSampleBuffer] {
        do {
            guard let videoTrack = (try? tracks(.video))?.first else {
                return []
            }
            
            let reader = try AVAssetReader(asset: base)
            
            let readerOutputSettings: [String: Any] = [
                "\(kCVPixelBufferPixelFormatTypeKey)": Int(kCVPixelFormatType_32BGRA) // kCVPixelFormatType_32BGRA is important
            ]
            
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings) // nil, should give you raw frames
            readerOutput.alwaysCopiesSampleData = false
            
            if reader.canAdd(readerOutput) {
                reader.add(readerOutput)
            } else {
                throw PhotonError.canNotAddOutput
            }
            
            reader.startReading()
            
            var frames: [CMSampleBuffer] = []
            
            while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                if time.isValid {
                    frames.append(sampleBuffer)
                }
            }

            return frames
        } catch {
            return []
        }
    }
    
    public var firstFrameDuration: CMTime {
        do {
            guard let videoTrack = (try? tracks(.video))?.first else {
                return kCMTimeZero
            }
            
            let reader = try AVAssetReader(asset: base)
            
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil) // nil, should give you raw frames
            readerOutput.alwaysCopiesSampleData = false
            
            if reader.canAdd(readerOutput) {
                reader.add(readerOutput)
            } else {
                throw PhotonError.canNotAddOutput
            }
            
            reader.startReading()
            
            var secondFrameTime = kCMTimeZero
            
            while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                if time.seconds > 0.0 {
                    secondFrameTime = time
                    reader.cancelReading()
                    break
                }
            }
            
            return secondFrameTime
        } catch {
            assert(false, "error \(error.localizedDescription)")
            return kCMTimeZero
        }
    }
}

extension Photon where Base: AVAsset {
    
    public func load(values: [Value]) -> Bool {
        guard !values.isEmpty else {
            return false
        }
        
        let uniqueValues = Array(Set(values))
        var keys: [String] = []
        
        if uniqueValues.contains(.duration) && !isDurationLoaded {
            keys.append(Value.duration.rawValue)
        }
        
        if uniqueValues.contains(.tracks) && !isTracksLoaded {
            keys.append(Value.tracks.rawValue)
        }
        
        if uniqueValues.contains(.playable) && !isPlayableLoaded {
            keys.append(Value.playable.rawValue)
        }
        
        if !keys.isEmpty {
            let sessionWaitSemaphore = DispatchSemaphore(value: 0)
            base.loadValuesAsynchronously(forKeys: keys) {
                sessionWaitSemaphore.signal()
                return
            }
            _ = sessionWaitSemaphore.wait(timeout: DispatchTime.distantFuture)
        }
        
        let status = uniqueValues.map {
            return base.statusOfValue(forKey: $0.key, error: nil) == .loaded
        }
        
        return !status.contains(false)
    }
    
    public func snapshot() -> CGImage? {
        let timestamp = CMTime(seconds: 0.0, preferredTimescale: base.duration.timescale)
        
        let generator = AVAssetImageGenerator(asset: base)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = kCMTimeZero
        generator.requestedTimeToleranceBefore = kCMTimeZero
        
        var timePicture = kCMTimeZero
        
        do {
            return try generator.copyCGImage(at: timestamp, actualTime: &timePicture)
        } catch {
            return nil
        }
    }
}

extension Photon where Base: AVMutableComposition {
    
    @discardableResult
    private func add(_ track: AVAssetTrack, at startTime: CMTime = kCMTimeZero, timeRange: CMTimeRange, scaleFactor: Float = 0.0) throws -> AVMutableCompositionTrack {
        let compositionTrack: AVMutableCompositionTrack
        let compositionTracks = base.tracks(withMediaType: track.mediaType)
        
        if compositionTracks.count > 0 {
            compositionTrack = compositionTracks[0]
        } else {
            compositionTrack = base.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)!
        }
        
        compositionTrack.preferredTransform = track.preferredTransform
        
        do {
            try compositionTrack.insertTimeRange(timeRange, of: track, at: startTime)
            
            if scaleFactor != 0.0 && scaleFactor != 1.0 {
                let scaledDuration = CMTime(value: Int64(Float(timeRange.duration.value)*scaleFactor), timescale:  timeRange.duration.timescale)
                let originalTimeRange = CMTimeRange(start: kCMTimeZero, duration: timeRange.duration)
                compositionTrack.scaleTimeRange(originalTimeRange, toDuration: scaledDuration)
            }
            
            return compositionTrack
        } catch {
            throw error
        }
    }
    
    private func add(_ track: Track, from asset: AVAsset, withScaleFactor scaleFactor: Float = 0.0, maxBounds bounds: CMTime = kCMTimeInvalid) throws {
        switch track {
        case .video:
            
            var videoDuration = kCMTimeZero
            let videoTracks = try asset.ph.tracks(.video)
            
            for track in videoTracks {
                
                var timeRange = track.timeRange
                let startTime = timeRange.start
                
                videoDuration = videoDuration + (startTime + timeRange.duration)
                
                if bounds.isValid && videoDuration > bounds {
                    let duration = (timeRange.duration - (videoDuration - bounds))
                    timeRange = CMTimeRange(start: timeRange.start, duration: duration)
                }
                try add(track, at: startTime, timeRange: timeRange, scaleFactor: scaleFactor)
            }
            
        case .audio:
            
            var audioDuration = kCMTimeZero
            let audioTracks = try asset.ph.tracks(.audio)
            
            for track in audioTracks {
                
                var timeRange = track.timeRange
                let startTime = timeRange.start
                
                audioDuration = audioDuration + (startTime + timeRange.duration)
                
                if bounds.isValid && audioDuration > bounds {
                    let duration = (timeRange.duration - (audioDuration - bounds))
                    timeRange = CMTimeRange(start: timeRange.start, duration: duration)
                }
                
                try add(track, at: startTime, timeRange: timeRange, scaleFactor: scaleFactor)
            }
        }
    }
    
    private func add(_ segments: [AVAsset], hasAudio: Bool) throws {
        // if self is a empty AVMutableComposition, self.duration is kCMTimeZero.
        var totalDuration = base.duration
        
        for asset in segments {
            
            var videoDuration = kCMTimeZero
            let videoTracks = try asset.ph.tracks(.video)
            
            for track in videoTracks {
                let timeRange = track.timeRange
                let startTime = timeRange.start + totalDuration
                try add(track, at: startTime, timeRange: timeRange)
                videoDuration = videoDuration + (startTime + timeRange.duration)
            }
            
            if hasAudio {
                
                var audioDuration = kCMTimeZero
                let audioTracks = try asset.ph.tracks(.audio)
                
                for track in audioTracks {
                    
                    var timeRange = track.timeRange
                    let startTime = timeRange.start + totalDuration
                    
                    audioDuration = audioDuration + (startTime + timeRange.duration)
                    
                    if audioDuration > videoDuration {
                        let duration = (timeRange.duration - (audioDuration - videoDuration))
                        timeRange = CMTimeRange(start: timeRange.start, duration: duration)
                    }
                    
                    try add(track, at: startTime, timeRange: timeRange)
                }
            }
            
            totalDuration = base.duration
        }
    }
    
    public var mixVideoComposition: AVMutableVideoComposition? {
        guard let compositionTrack = base.tracks(withMediaType: .video).first else {
            return nil
        }
        
        guard let videoTrack = (try? tracks(.video))?.first else {
            return nil
        }
        
        let videoDuration = base.duration
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        
        mainInstruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: videoDuration)
        let videolayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        
        var isVideoAssetPortrait = false
        let videoTransform = videoTrack.preferredTransform
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        
        videolayerInstruction.setTransform(videoTrack.preferredTransform, at: kCMTimeZero)
        videolayerInstruction.setOpacity(0.0, at: videoDuration)
        
        mainInstruction.layerInstructions = [videolayerInstruction]
        
        let mixVideoComposition = AVMutableVideoComposition()
        
        var naturalSize = videoTrack.naturalSize
        if isVideoAssetPortrait {
            naturalSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        }
        
        mixVideoComposition.renderSize = naturalSize
        mixVideoComposition.instructions = [mainInstruction]
        mixVideoComposition.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
        
        return mixVideoComposition
    }
}
