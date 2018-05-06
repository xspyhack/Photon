//
//  ElectronVideoCompositor.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

class ElectronVideoCompositor : NSObject, AVVideoCompositing {
    
    private let renderingQueue = DispatchQueue(label: "com.blessingsoft.photon.rendering", qos: .default)
    
    private var renderContextQueue = DispatchQueue(label: "com.blessingsoft.photon.rendercontext")
    
    var shouldCancelAllRequests = false
    
    enum PixelBufferRequestError : Error {
        case newRenderedPixelBufferForRequestFailure
    }
    
    private var internalRenderContextDidChange = false
    
    private var renderContextDidChange: Bool {
        get {
            return renderContextQueue.sync { internalRenderContextDidChange }
        }
        set (newRenderContextDidChange) {
            renderContextQueue.sync { internalRenderContextDidChange = newRenderContextDidChange }
        }
    }
    
    private var renderContext: AVVideoCompositionRenderContext?
    
    var sourcePixelBufferAttributes: [String : Any]? = [
        String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)
    ]
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)
    ]
    
    private var renderer: TweeningPixelBufferRenderer
    
    override init() {
        fatalError("Fata error")
    }
    
    fileprivate init(renderer: TweeningPixelBufferRenderer) {
        self.renderer = renderer
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync {
            renderContext = newRenderContext
        }
        
        renderContextDidChange = true
    }
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        autoreleasepool {
            renderingQueue.async {
                // Check if all pending requests have been cancelled.
                if self.shouldCancelAllRequests {
                    asyncVideoCompositionRequest.finishCancelledRequest()
                } else {
                    
                    guard let resultPixels =
                        self.newRenderedPixelBuffer(for: asyncVideoCompositionRequest) else {
                            asyncVideoCompositionRequest.finish(with: PixelBufferRequestError.newRenderedPixelBufferForRequestFailure)
                            return
                    }
                    
                    // The resulting pixelbuffer from Metal renderer is passed along to the request.
                    asyncVideoCompositionRequest.finish(withComposedVideoFrame: resultPixels)
                }
            }
        }
    }
    
    func cancelAllPendingVideoCompositionRequests() {
        /*
         Pending requests will call finishCancelledRequest, those already rendering will call
         finishWithComposedVideoFrame.
         */
        renderingQueue.sync {
            shouldCancelAllRequests = true
        }
        
        renderingQueue.async {
            // Start accepting requests again.
            self.shouldCancelAllRequests = false
        }
    }
    
    func factor(for time: CMTime, in range: CMTimeRange) -> Float64 {
        
        let elapsed = time - range.start
        
        return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration)
    }
    
    func newRenderedPassthroughPixelBuffer(for request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
        guard let currentInstruction = request.videoCompositionInstruction as? ElectronVideoCompositionInstruction else {
            return nil
        }
        
        guard let layerInstruction = currentInstruction.layerInstructions.first else {
            return nil
        }

        // Destination pixel buffer into which we render the output.
        guard let pixelBuffer = renderContext?.newPixelBuffer() else {
            return nil
        }
        
        let trackID = layerInstruction.trackID
        
        guard let sourceBuffer = request.sourceFrame(byTrackID: trackID) else {
            return nil
        }
        
        guard let filter = layerInstruction.filter else {
            return nil
        }
        
        let renderer = FilterRenderer(filter: filter)
        guard let frame = renderer?.applying(to: EffectPixelBuffer(source: sourceBuffer)) else {
            return nil
        }
        
        renderer?.render(frame, to: pixelBuffer)
       
        return pixelBuffer
    }
    
    func pixedTransform(transform: CGAffineTransform, extent: CGRect) -> CGAffineTransform {
        let rect = extent.applying(transform)
        var t = CGAffineTransform(scaleX: 1, y: -1)
        t = t.concatenating(CGAffineTransform(translationX: 0, y: extent.height))
        t = t.concatenating(transform)
        t = t.concatenating(CGAffineTransform(scaleX: 1, y: -1))
        t = t.concatenating(CGAffineTransform(translationX: 0, y: rect.height))
        return t
    }
    
    func newRenderedPixelBuffer(for request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
        
        let tweenFactor = factor(for: request.compositionTime, in: request.videoCompositionInstruction.timeRange)
       
        print(request.compositionTime)
        
        guard let currentInstruction = request.videoCompositionInstruction as? ElectronVideoCompositionInstruction else {
                return nil
        }
        
        if !currentInstruction.containsTweening, currentInstruction.layerInstructions.count == 1 {
            return newRenderedPassthroughPixelBuffer(for: request)
        } else {
            
        
        
        // Source pixel buffers are used as inputs while rendering the transition.
        guard let foregroundSourceBuffer = request.sourceFrame(byTrackID: currentInstruction.foregroundTrackID) else {
            return nil
        }
        
        guard let backgroundSourceBuffer = request.sourceFrame(byTrackID: currentInstruction.backgroundTrackID) else {
            return nil
        }
        
        // Destination pixel buffer into which we render the output.
        guard let pixelBuffer = renderContext?.newPixelBuffer() else {
            return nil
        }
        
        // Recompute normalized render transform everytime the render context changes
        if renderContextDidChange, let renderContext = renderContext {
            renderContextDidChange = false
            
            // for open gl
            let renderSize = renderContext.size
            let destinationSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            let renderContextTransform = CGAffineTransform(a: renderSize.width / 2, b: 0, c: 0, d: renderSize.height / 2, tx: renderSize.width / 2, ty: renderSize.height / 2)
            let destinationTransfrom = CGAffineTransform(a: 2 / destinationSize.width, b: 0, c: 0, d: 2 / destinationSize.height, tx: -1, ty: -1)
            
            let normalizedRenderTransform = renderContextTransform.concatenating(renderContext.renderTransform).concatenating(destinationTransfrom)
            
            renderer.transform = normalizedRenderTransform
        }
        
        let tweenPixelBuffer = TweenPixelBuffer(foreground: foregroundSourceBuffer, background: backgroundSourceBuffer, factor: Float(tweenFactor))
        
        renderer.render(pixelBuffer, using: tweenPixelBuffer)
        
        return pixelBuffer
        }
    }
}

class CrossDissolveVideoCompositor : ElectronVideoCompositor {
    
    override init() {
        let renderer = CrossDissolveRenderer()
        super.init(renderer: renderer)
    }
}
