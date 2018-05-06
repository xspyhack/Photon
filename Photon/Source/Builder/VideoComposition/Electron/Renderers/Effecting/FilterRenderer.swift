//
//  FilterRenderer.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 28/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import Foundation

struct FilterRenderer : EffectingPixelBufferRenderer {
    
    let context: CIContext
    
    var filter: CIFilter
    
    var transform: CGAffineTransform = .identity
    
    init?(filter: CIFilter) {
        guard let eaglContext = EAGLContext(api: .openGLES2) else {
            return nil
        }
        
        self.filter = filter
        
        self.context = CIContext(eaglContext: eaglContext, options: [kCIContextWorkingColorSpace: NSNull()])
    }
    
    func render(_ image: CIImage, to buffer: CVPixelBuffer) {
        context.render(image, to: buffer)
    }
    
    func applying(to buffer: EffectPixelBuffer) -> CIImage? {
        let sourceImage = CIImage(cvImageBuffer: buffer.source)
        
        let image = sourceImage.transformed(by: transform)
        
        // filter
        filter.setValue(image, forKey: kCIInputImageKey)
        
        guard let filteredImage = filter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("CIFilter failed to render image")
            return nil
        }
        
        return filteredImage
    }
}
