//
//  PreviewView.swift
//  Photon
//
//  Created by k on 2017/10/23.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import UIKit
import AVFoundation

public enum PreviewViewStatus {
    case unknown
    case readyToPlay
    case play
    case pause
    case playToEndTime
    case failed
}

public class PreviewView : UIView {
    
    var filter: CIFilter?
    
    public private(set) var status: PreviewViewStatus = .unknown
    
    private let imageView = UIImageView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        imageView.frame = frame
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
    }
    
    public func display(pixelBuffer: CVPixelBuffer) {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        guard let filter = filter else {
            imageView.image = UIImage(ciImage: image)
            return
        }
        
        // apply filter to image
        filter.setValue(image, forKey: kCIInputImageKey)
        imageView.image = filter.outputImage.flatMap { UIImage(ciImage: $0) }
    }
}
