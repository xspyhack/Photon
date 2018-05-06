//
//  VideoCompositionBuilder.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 19/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public func build(asset: AVAsset) {
    // AVAsynchronousVideoCompositionRequest
    let filter = CIFilter(name: "CIGaussianBlur")!
    let composition = AVVideoComposition(asset: asset) { request in
        
        // Clamp to avoid blurring transparent pixels at the image edges
        let source = request.sourceImage.clampedToExtent()
        filter.setValue(source, forKey: kCIInputImageKey)
        
        // Vary filter parameters based on video timing
        let seconds = request.compositionTime.seconds
        filter.setValue(seconds * 10.0, forKey: kCIInputRadiusKey)
        
        // Crop the blurred output to the bounds of the original image
        let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
        
        // Provide the filter output to the composition
        request.finish(with: output, context: nil)
    }
}

protocol VideoCompositionBuilder {
    
    var preferredVideoSize: CGSize { get }
    
    var preferredFrameDuration: CMTime { get }
    
    var fillMode: FillMode { get }

    var videoComposition: AVMutableVideoComposition? { get }
    
    associatedtype C : Composition
    
    func build(in composition: C) -> AVMutableVideoComposition
}

extension VideoCompositionBuilder {
    
    var preferredVideoSize: CGSize { return .zero }
    
    var preferredFrameDuration: CMTime { return CMTime(value: 1, timescale: 30) } // default 30fps
    
    var fillMode: FillMode { return .aspectFill }
    
    var videoComposition: AVMutableVideoComposition? { return nil }
}
