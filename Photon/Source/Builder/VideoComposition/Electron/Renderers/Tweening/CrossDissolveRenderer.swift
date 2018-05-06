//
//  CrossDissolveRenderer.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 28/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import Foundation

struct CrossDissolveRenderer : TweeningPixelBufferRenderer {
    
    var transform: CGAffineTransform = .identity
    
   
    func render(_ image: CIImage, to buffer: CVPixelBuffer) {
        //
    }
    
    
    func render(_ pixelBuffer: PixelBuffer, using tweenPixelBuffer: TweenPixelBuffer) {

        let frameImage = CIImage(cvPixelBuffer: pixelBuffer)
       
        let foreground = tweenPixelBuffer.foreground
        let background = tweenPixelBuffer.background
        
        
    }
}
