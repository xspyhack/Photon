//
//  CGImage+Photon.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 01/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import Foundation

extension CGImage : PhotonCompatible {}

extension Photon where Base: CGImage {

    func resized(to size: CGSize, mode: FrameContentMode) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(4 * size.width), space: colorSpace, bitmapInfo: self.base.bitmapInfo.rawValue) ?? CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(4 * size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            return nil
        }
        
        let oldSize = CGSize(width: self.base.width, height: self.base.height)
        
        let verticalRatio = CGFloat(Float(size.height / oldSize.height).rounded(to: 2))
        let horizontalRatio = CGFloat(Float(size.width / oldSize.width).rounded(to: 2))
        var thumbnailPoint = CGPoint.zero
        var thumbnailRect = CGRect.zero
        
        switch mode {
        case .aspectFill, .default:
            if verticalRatio < horizontalRatio {
                thumbnailPoint.y = (size.height - oldSize.height * horizontalRatio) / 2
                thumbnailRect.size = CGSize(width: size.width, height: oldSize.height * horizontalRatio)
            } else if horizontalRatio < verticalRatio {
                thumbnailPoint.x = (size.width - oldSize.width * verticalRatio) / 2
                thumbnailRect.size = CGSize(width: oldSize.width * verticalRatio, height: size.height)
            } else {
                thumbnailRect.size = size
            }
            
            thumbnailRect.origin = thumbnailPoint
            
            context.draw(self.base, in: thumbnailRect)
            
        case .aspectFit:
            
            if verticalRatio < horizontalRatio {
                thumbnailPoint.x = (size.width - oldSize.width * verticalRatio) / 2
                thumbnailRect.size = CGSize(width: oldSize.width * verticalRatio, height: size.height)
            } else if horizontalRatio < verticalRatio {
                thumbnailPoint.y = (size.height - oldSize.height * horizontalRatio) / 2
                thumbnailRect.size = CGSize(width: size.width, height: oldSize.height * horizontalRatio)
            } else {
                thumbnailRect.size = size
            }
            
            thumbnailRect.origin = thumbnailPoint
            
            context.draw(self.base, in: thumbnailRect)
        }
        
        return context.makeImage()
    }
}


extension Float {
    
    func rounded(to places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}
