//
//  DebugView.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 18/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation

struct CompositionTrackSegmentInfo : CustomStringConvertible {
    let timeRange: CMTimeRange
    let isEmpty: Bool
    let mediaType: AVMediaType
    
    private let name: String

    init(segment: AVCompositionTrackSegment, mediaType: AVMediaType) {
        
        let timeRange = segment.isEmpty ? segment.timeMapping.target : segment.timeMapping.source
        
        self.timeRange = timeRange
        self.isEmpty = segment.isEmpty
        self.mediaType = mediaType
        
        self.name = segment.sourceURL?.lastPathComponent ?? ""
    }
    
    var description: String {
        guard !isEmpty else {
            return ""
        }
        
        var description = String(format: "%1.1f - %1.1f: \"%@\"", timeRange.start.seconds, timeRange.end.seconds, name)
        
        let type: String
        switch mediaType {
        case .video:
            type = "(v)"
        case .audio:
            type = "(a)"
        default:
            type = "\(mediaType)"
        }
        
        description = description + type
        
        return description
    }
}

struct VideoCompositionStageInfo {
    let timeRange: CMTimeRange
    let layerNames: [String]
    let opacityRamps: [String: RampInfo]
    
    init?(instruction: AVVideoCompositionInstructionProtocol) {
        
        guard let instruction = instruction as? AVVideoCompositionInstruction else {
            return nil
        }
        
        var rampsDictionary: [String: RampInfo] = [:]
        
        let layerNames = instruction.layerInstructions.map { layerInstruction -> String in
            
            let ramp = RampInfo(layerInstruction: layerInstruction)
            
            let name = "\(layerInstruction.trackID)"
            rampsDictionary[name] = ramp
            
            return name
        }
        
        self.timeRange = instruction.timeRange
        self.layerNames = layerNames
        self.opacityRamps = rampsDictionary
    }
}

struct RampInfo {
    
    let ramp: [CGPoint]
    
    init(layerInstruction: AVVideoCompositionLayerInstruction) {
        
        var ramp: [CGPoint] = []
        var startTime = kCMTimeZero
        var startOpacity: Float = 1.0
        var endOpacity: Float = 1.0
        var timeRange = kCMTimeRangeZero
        
        while layerInstruction.getOpacityRamp(for: startTime, startOpacity: &startOpacity, endOpacity: &endOpacity, timeRange: &timeRange) {
            
            if startTime == kCMTimeZero && timeRange.start > kCMTimeZero {
                ramp.append(CGPoint(x: timeRange.start.seconds, y: Double(startOpacity)))
            }
            ramp.append(CGPoint(x: timeRange.end.seconds, y: Double(endOpacity)))
            startTime = timeRange.end
        }
        
        self.ramp = ramp
    }
    
    init(input: AVAudioMixInputParameters, duration: CMTime) {
        
        var ramp: [CGPoint] = []
        var startTime = kCMTimeZero
        var startVolume: Float = 1.0
        var endVolume: Float = 1.0
        var timeRange = kCMTimeRangeZero
        
        while input.getVolumeRamp(for: startTime, startVolume: &startVolume, endVolume: &endVolume, timeRange: &timeRange) {
            if startTime == kCMTimeZero && timeRange.start > kCMTimeZero {
                ramp.append(CGPoint(x: 0, y: 1.0))
                ramp.append(CGPoint(x: timeRange.start.seconds, y: 1.0))
            }
            
            ramp.append(CGPoint(x: timeRange.start.seconds, y: Double(startVolume)))
            ramp.append(CGPoint(x: timeRange.end.seconds, y: Double(endVolume)))
            
            startTime = timeRange.end
        }
        
        if startTime < duration {
            ramp.append(CGPoint(x: duration.seconds, y: Double(endVolume)))
        }
        
        self.ramp = ramp
    }
}


public class DebugView : UIView {
    
    lazy var drawingLayer: CALayer = {
        return self.layer
    }()
    
    private var duration: CMTime = kCMTimeZero
    private var compositionRectWidth: CGFloat = 0
    
    private var compositionTracks: [[CompositionTrackSegmentInfo]] = []
    
    private var videoCompositionStages: [VideoCompositionStageInfo] = []
    
    private var audioMixTracks: [RampInfo] = []
    
    private var scaledDurationToWidth: CGFloat = 0
    
    private struct Constant {
        static let leftInsetToMatchTimeSlider: CGFloat = 50
        static let rightInsetToMatchTimeSlider: CGFloat = 60
        static let leftMarginInset: CGFloat = 4
        static let bannerHeight: CGFloat = 20
        static let idealRowHeight: CGFloat = 36
        static let gapAfterRows: CGFloat = 4
    }
    
    public var player: AVPlayer?
    
    public func synchronize(to composition: AVComposition?, videoComposition: AVVideoComposition?, audioMix: AVAudioMix?) {
        // reset info
        reset()
        
        if let composition = composition {
            let tracks = composition.tracks.map { track -> [CompositionTrackSegmentInfo] in
                let segments = track.segments.map {
                    CompositionTrackSegmentInfo(segment: $0, mediaType: track.mediaType)
                }
                
                return segments
            }
            
            compositionTracks = tracks
            duration = max(duration, composition.duration)
        }
        
        if let videoComposition = videoComposition {
            let stages = videoComposition.instructions.flatMap {
                VideoCompositionStageInfo(instruction: $0)
            }
            
            videoCompositionStages = stages
        }
        
        if let audioMix = audioMix {
            let mixTracks = audioMix.inputParameters.map {
                RampInfo(input: $0, duration: self.duration)
            }
            
            audioMixTracks = mixTracks
        }
        
        drawingLayer.setNeedsDisplay()
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
         super.willMove(toSuperview: newSuperview)
        
        drawingLayer.frame = bounds
        drawingLayer.delegate = self
        drawingLayer.setNeedsDisplay()
    }
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let drawRect = rect.insetBy(dx: Constant.leftMarginInset, dy: 4.0)
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        let textAttributes: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.white, .paragraphStyle: style]
        let numBanners = (compositionTracks.isEmpty ? 0 : 1) + (videoCompositionStages.isEmpty ? 0 : 1) + (audioMixTracks.isEmpty ? 0 : 1)
        let numRows = compositionTracks.count + videoCompositionStages.count + audioMixTracks.count
        
        let totalBannerHeight = CGFloat(numBanners) * (Constant.bannerHeight + Constant.gapAfterRows)
        var rowHeight = Constant.idealRowHeight
        if numRows > 0 {
            let maxRowHeight = (drawRect.size.height - totalBannerHeight) / CGFloat(numRows)
            rowHeight = min(rowHeight, maxRowHeight)
        }
        
        var runningTop = rect.origin.y
        var bannerRect = drawRect
        bannerRect.size.height = Constant.bannerHeight
        bannerRect.origin.y = runningTop
        
        var rowRect = drawRect
        rowRect.size.height = rowHeight
        
        rowRect.origin.x += Constant.leftInsetToMatchTimeSlider;
        rowRect.size.width -= (Constant.leftInsetToMatchTimeSlider + Constant.rightInsetToMatchTimeSlider)
        compositionRectWidth = rowRect.size.width
        
        scaledDurationToWidth = compositionRectWidth / CGFloat(duration.seconds)
       
        // Compositoin
        if !compositionTracks.isEmpty {
            bannerRect.origin.y = runningTop
            context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // white
            "AVComposition".draw(in: bannerRect, withAttributes: [.foregroundColor: UIColor.white])
            
            runningTop += bannerRect.size.height
            
            for track in compositionTracks {
                
                rowRect.origin.y = runningTop
                var segmentRect = rowRect
                for segment in track {
                    
                    segmentRect.size.width = CGFloat(segment.timeRange.duration.seconds) * scaledDurationToWidth
                    
                    if segment.isEmpty {
                        context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // white
                        "Empty".ph.drawVerticallyCentered(in: segmentRect, withAttributes: textAttributes)
                    } else {
                        if segment.mediaType == .video {
                            context.setFillColor(red: 0.0, green: 0.36, blue: 0.36, alpha: 1.0) // blue-green
                            context.setStrokeColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0) // brigher blue-green
                        } else {
                            context.setFillColor(red: 0.0, green: 0.36, blue: 0.36, alpha: 1.0) // blue-green
                            context.setStrokeColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0) // brigher blue-green
                        }
                        
                        context.setLineWidth(2.0)
                        context.addRect(segmentRect.insetBy(dx: 3.0, dy: 3.0))
                        context.drawPath(using: .fillStroke)

                        context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // white
                        segment.description.ph.drawVerticallyCentered(in: segmentRect, withAttributes: textAttributes)
                    }
                    
                    segmentRect.origin.x += segmentRect.size.width
                }
                
                runningTop += rowRect.size.height
            }
            runningTop += Constant.gapAfterRows
        }

        // VideoComposition
        if !videoCompositionStages.isEmpty {
            bannerRect.origin.y = runningTop
            context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            "AVVideoComposition".draw(in: bannerRect, withAttributes: [.foregroundColor: UIColor.white])
            runningTop += bannerRect.size.height
            
            rowRect.origin.y = runningTop
            var stageRect = rowRect
            
            for stage in videoCompositionStages {
                stageRect.size.width = CGFloat(stage.timeRange.duration.seconds) * scaledDurationToWidth
                
                let layerCount = stage.layerNames.count
                var layerRect = stageRect
                
                if layerCount > 0 {
                    layerRect.size.height /= CGFloat(layerCount)
                }
                
                for layerName in stage.layerNames {
                    if Int(layerName)! % 2 == 1 {
                        context.setFillColor(red: 0.55, green: 0.02, blue: 0.02, alpha: 1.0) // darker red
                        context.setStrokeColor(red: 0.87, green: 0.10, blue: 0.10, alpha: 1.0) // brighter red
                    } else {
                        context.setFillColor(red: 0.00, green: 0.40, blue: 0.76, alpha: 1.0) // dardker blue
                        context.setStrokeColor(red: 0.00, green: 0.67, blue: 1.0, alpha: 1.0) // brighter blue
                    }
                    
                    context.setLineWidth(2.0)
                    context.addRect(layerRect.insetBy(dx: 3.0, dy: 1.0))
                    context.drawPath(using: .fillStroke)

                    // (if there are two layers, the first should ideally have a gradient fill.)
                    context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // white
                    layerName.ph.drawVerticallyCentered(in: layerRect, withAttributes: textAttributes)

                    // Draw the opacity ramps for each layer as per the layerInstructions
                    if let ramps = stage.opacityRamps[layerName], !ramps.ramp.isEmpty {
                        var rampRect = layerRect
                        rampRect.size.width = CGFloat(duration.seconds) * scaledDurationToWidth
                        rampRect = rampRect.insetBy(dx: 3.0, dy: 3.0)
                        
                        context.beginPath()
                        context.setStrokeColor(red: 0.95, green: 0.68, blue: 0.09, alpha: 1.0)
                        context.setLineWidth(2.0)
                        
                        var firstPoint = true
                        
                        for point in ramps.ramp {
                            let timeVolumePoint = point
                            var pointInRow: CGPoint = .zero
                            pointInRow.x = horizontalPosition(forTime: CMTime(seconds: Float64(timeVolumePoint.x * 600), preferredTimescale: Defaults.preferredTimescale))
                            pointInRow.y = rampRect.origin.y + (0.9 - 0.8 * timeVolumePoint.y) * rampRect.size.height
                            
                            pointInRow.x = max(pointInRow.x, rampRect.minX)
                            pointInRow.x = min(pointInRow.x, rampRect.maxX)
                            
                            if firstPoint {
                                context.move(to: pointInRow)
                                firstPoint = false
                            } else {
                                context.addLine(to: pointInRow)
                            }
                        }
                        
                        context.strokePath()
                    }
                    
                    layerRect.origin.y += layerRect.size.height
                }
                
                stageRect.origin.x += stageRect.size.width
            }
            
            runningTop += rowRect.size.height
            runningTop += Constant.gapAfterRows
        }
        
        // AudioMix
        if !audioMixTracks.isEmpty {
            bannerRect.origin.y = runningTop
            context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // white
            "AVAudioMix".draw(in: bannerRect, withAttributes: [.foregroundColor: UIColor.white])
            runningTop += bannerRect.size.height
            
            for mixTrack in audioMixTracks {
                rowRect.origin.y = runningTop
                
                var rampRect = rowRect
                rampRect.size.width = CGFloat(duration.seconds) * scaledDurationToWidth
                rampRect = rampRect.insetBy(dx: 3.0, dy: 3.0)
                
                context.setFillColor(red: 0.55, green: 0.02, blue: 0.02, alpha: 1.0) // darker red
                context.setStrokeColor(red: 0.87, green: 0.10, blue: 0.10, alpha: 1.0) // brighter red
                context.setLineWidth(2.0)
                context.addRect(rampRect)
                context.drawPath(using: .fillStroke)
                
                context.setStrokeColor(red: 0.95, green: 0.68, blue: 0.09, alpha: 1.0) // yellow
                context.setLineWidth(3.0)
                
                var firstPoint = true
                
                for point in mixTrack.ramp {
                    let timeVolumePoint = point
                    var pointInRow: CGPoint = .zero
                    
                    pointInRow.x = rampRect.origin.x + timeVolumePoint.x * scaledDurationToWidth
                    pointInRow.y = rampRect.origin.y + (0.9 - 0.8 * timeVolumePoint.y) * rampRect.size.height
                    
                    pointInRow.x = max(pointInRow.x, rampRect.minX)
                    pointInRow.x = min(pointInRow.x, rampRect.maxX)
                    
                    if firstPoint {
                        context.move(to: pointInRow)
                        firstPoint = false
                    } else {
                        context.addLine(to: pointInRow)
                    }
                }
                context.strokePath()
                
                runningTop += rowRect.size.height
            }
            
            runningTop += Constant.gapAfterRows
        }
        
        if !compositionTracks.isEmpty {
            layer.sublayers = nil
            let visibleRect = layer.bounds
            var currentTimeRect = visibleRect
            
            // The red band of the timeMarker will be 8 pixels wide
            currentTimeRect.origin.x = 0
            currentTimeRect.size.width = 8
            
            let timeMarkerRedBandLayer = CAShapeLayer()
            timeMarkerRedBandLayer.frame = currentTimeRect
            timeMarkerRedBandLayer.position = CGPoint(x: rowRect.origin.x, y: bounds.height / 2.0)
            
            let linePath = CGPath(rect: currentTimeRect, transform: nil)
            timeMarkerRedBandLayer.fillColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
            timeMarkerRedBandLayer.path = linePath
            
            currentTimeRect.origin.x = 0
            currentTimeRect.size.width = 1

            // Position the white line layer of the timeMarker at the center of the red band layer
            let timeMarkerWhiteLineLayer = CAShapeLayer()
            timeMarkerWhiteLineLayer.frame = currentTimeRect
            timeMarkerWhiteLineLayer.position = CGPoint(x: 4.0, y: bounds.height / 2)
            let whiteLinePath = CGPath(rect: currentTimeRect, transform: nil)
            timeMarkerWhiteLineLayer.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
            timeMarkerWhiteLineLayer.path = whiteLinePath

            // Add the white line layer to red band layer, by doing so we can only animate the red band layer which in turn animates its sublayers
            timeMarkerRedBandLayer .addSublayer(timeMarkerWhiteLineLayer)

            // This scrubbing animation controls the x position of the timeMarker
            // On the left side it is bound to where the first segment rectangle of the composition starts
            // On the right side it is bound to where the last segment rectangle of the composition ends
            // Playback at rate 1.0 would take the timeMarker "duration" time to reach from one end to the other, that is marked as the duration of the animation
            let scrubbingAnimation = CABasicAnimation(keyPath: "position.x")
            scrubbingAnimation.fromValue = horizontalPosition(forTime: kCMTimeZero)
            scrubbingAnimation.toValue = horizontalPosition(forTime: duration)
            scrubbingAnimation.isRemovedOnCompletion = false
            scrubbingAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
            scrubbingAnimation.duration = duration.seconds
            scrubbingAnimation.fillMode = kCAFillModeBoth
            
            timeMarkerRedBandLayer.add(scrubbingAnimation, forKey: nil)
            
            // We add the red band layer along with the scrubbing animation to a AVSynchronizedLayer to have precise timing information
            if let player = player, let currentItem = player.currentItem {
                let syncLayer = AVSynchronizedLayer(playerItem: currentItem)
                syncLayer.addSublayer(timeMarkerRedBandLayer)
                layer.addSublayer(syncLayer)
            }
        }
    }
    
    func viewWillDisappear(animated: Bool) {
        drawingLayer.delegate = self
    }
    
    private func reset() {
        compositionTracks = []
        videoCompositionStages = []
        audioMixTracks = []
        
        duration = CMTime(value: 1, timescale: 1)
        
    }
    
    private func horizontalPosition(forTime time: CMTime) -> CGFloat {
        var seconds: Float64 = 0;
        if time.isNumeric && time > kCMTimeZero {
            seconds = time.seconds
        }
        
        return CGFloat(seconds) * scaledDurationToWidth + Constant.leftInsetToMatchTimeSlider + Constant.leftMarginInset;
    }
}

