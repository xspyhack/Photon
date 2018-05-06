//
//  PixelBufferRenderer.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 13/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation
import OpenGLES

typealias PixelBuffer = CVPixelBuffer

class TweenPixelBuffer {
    let foreground: PixelBuffer
    let background: PixelBuffer
    
    let factor: Float
    
    init(foreground: PixelBuffer, background: PixelBuffer, factor: Float) {
        self.foreground = foreground
        self.background = background
        self.factor = factor
    }
}

class EffectPixelBuffer {
    let source: PixelBuffer
    
    init(source: PixelBuffer) {
        self.source = source
    }
}

protocol PixelBufferRenderer {
    
    var transform: CGAffineTransform { get set }
    
    func render(_ image: CIImage, to buffer: CVPixelBuffer)
    
    //func render(_ pixelBuffer: PixelBuffer, using sourcePixelBuffer: SourcePixelBuffer)
}

protocol EffectingPixelBufferRenderer : PixelBufferRenderer {
    func applying(to buffer: EffectPixelBuffer) -> CIImage?
}

protocol TweeningPixelBufferRenderer : PixelBufferRenderer {
    func render(_ pixelBuffer: PixelBuffer, using sourcePixelBuffer: TweenPixelBuffer)
}

