//
//  VideoGenerator.swift
//  Photon
//
//  Created by k on 2017/10/23.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import UIKit
import AVFoundation

public enum FrameContentMode : UInt {
    case aspectFill
    case aspectFit
    case `default`
}

public struct VideoGenerator {
    
    private let videoSize: CGSize
    
    private let fps: UInt
    
    private let contentMode: FrameContentMode
    
    private let frameDuration: Float64

    private let transitionRenderer: FrameTransitionRenderer
    
    private let transitionDuration: Float64
    
    private let frameCount = 60
    private let transitionFrameCount = 10
    
    public init(videoSize: CGSize, fps: UInt = 60, contentMode: FrameContentMode = .default, frameDuration: Float64, transitionRenderer: FrameTransitionRenderer, transitionDuration: Float64) {
        self.videoSize = videoSize
        self.fps = fps
        self.contentMode = contentMode
        
        self.frameDuration = frameDuration
        
        self.transitionRenderer = transitionRenderer
        self.transitionDuration = transitionDuration
    }
    
    public func generateAsynchronously(images: [UIImage], to url: URL, completionHandler: ((Result<Bool>) -> Void)? = nil) throws {
        
        let writer = try AVAssetWriter(url: url, fileType: .mp4)
        
        let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecH264,
                                            AVVideoWidthKey: self.videoSize.width,
                                            AVVideoHeightKey: self.videoSize.height]
        
        if !writer.canApply(outputSettings: videoSettings, forMediaType: .video) {
            throw NSError(domain: "can not apply settings", code: 0, userInfo: nil)
        }
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        let attributes: [String: Any] = [String(kCVPixelBufferPixelFormatTypeKey): Int32(kCVPixelFormatType_32ARGB),
                                         String(kCVPixelBufferCGImageCompatibilityKey): true,
                                         String(kCVPixelBufferCGBitmapContextCompatibilityKey): true]
        
        let writerAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: attributes)
        
        if !writer.canAdd(writerInput) {
            throw writer.error ?? NSError(domain: "can not add videoInput", code: 0, userInfo: nil)
        }
        
        writer.add(writerInput)
        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "failed to start writing", code: 0, userInfo: nil)
        }
        writer.startSession(atSourceTime: kCMTimeZero)
        
        assert(writerAdaptor.pixelBufferPool != nil, "pixel buffer bool is nil")
        
        let writerQueue = DispatchQueue(label: "com.blessingsoft.photon.writer")
        var frame = 0
        
        writerInput.requestMediaDataWhenReady(on: writerQueue) {
            
            while writerInput.isReadyForMoreMediaData && frame < images.count * self.frameCount {
                
                let index = frame / self.frameCount
                
                guard let current = images.safe[index]?.cgImage?.ph.resized(to: self.videoSize, mode: self.contentMode) else { return }
                
                let mod = frame % self.frameCount
                let frameProgress = Float(mod) / Float(self.frameCount)
                
                let transitioning = mod >= self.frameCount - self.transitionFrameCount && index + 1 < images.count
                let transitionFrame: TransitionFrame
                if transitioning {
                    let previous: Frame? = images.safe[index - 1]?.cgImage?.ph.resized(to: self.videoSize, mode: self.contentMode).flatMap { ($0, 1.0) }
                    let next: Frame? = images.safe[index + 1]?.cgImage?.ph.resized(to: self.videoSize, mode: self.contentMode).flatMap { ($0, 0.0) }
                    
                    let transitionProgress = Float(mod - (self.frameCount - self.transitionFrameCount)) / Float(self.transitionFrameCount)
                    
                    transitionFrame = TransitionFrame(current: (current, frameProgress), previous: previous, next: next, progress: transitionProgress)
                } else {
                    transitionFrame = TransitionFrame(current: (current, frameProgress), previous: nil, next: nil, progress: 1.0)
                }

                if (!self.appendPixelBuffer(from: transitionFrame, to: writerAdaptor, withPresentationTime: CMTime(value: Int64(frame), timescale: Int32(self.fps)))) {
                    print("Append pixel buffer failed at index: \(index), \(writer.error!)")
                }
                
                frame += 1
            }
            
            writerInput.markAsFinished()
            writer.finishWriting {
                completionHandler?(.success(true))
            }
        }
    }
    
    private func appendPixelBuffer(from frame: Frame,
                                   to writerAdaptor: AVAssetWriterInputPixelBufferAdaptor,
                                   withPresentationTime presentationTime: CMTime) -> Bool {

        return true
    }
    
    private func appendPixelBuffer(from transitionFrame: TransitionFrame,
                                   to writerAdaptor: AVAssetWriterInputPixelBufferAdaptor,
                                   withPresentationTime presentationTime: CMTime) -> Bool {
        var success = false
        
        autoreleasepool {
            guard let pixelBufferPool = writerAdaptor.pixelBufferPool else {
                return
            }
            
            let pixelBufferOut = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
            let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, pixelBufferOut)
            
            guard let pixelBuffer = pixelBufferOut.pointee, status == kCVReturnSuccess else {
                pixelBufferOut.deallocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
                return
            }
            
            fill(pixelBuffer: pixelBuffer, from: transitionFrame)
            
            success = writerAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
            
            pixelBufferOut.deinitialize()
            pixelBufferOut.deallocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
        }
        
        return success
    }
    
    private func fill(pixelBuffer: CVPixelBuffer, from frame: TransitionFrame) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        guard let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let size = videoSize
        
        guard let context = CGContext(data: pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            else {
                return
        }
        
        transitionRenderer.render(frame, using: context)
    }
}
