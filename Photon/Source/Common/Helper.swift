//
//  Helper.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 12/11/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation
import UIKit

public func orientation(preferredTransform: CGAffineTransform) -> UIImageOrientation {
    if preferredTransform.a == 0 && preferredTransform.b == 1.0 && preferredTransform.c == -1.0 && preferredTransform.d == 0 {
        // Portrait
        return .up
    } else if preferredTransform.a == 0 && preferredTransform.b == -1.0 && preferredTransform.c == 1.0 && preferredTransform.d == 0 {
        // PortraitUpsideDown
        return .down
    } else if preferredTransform.a == 1.0 && preferredTransform.b == 0 && preferredTransform.c == 0 && preferredTransform.d == 1.0 {
        // LandscapeRight
        return .right
    } else {
        // LandscapeLeft
        return .left
    }
}

public func transform(withOrientation orientation: UIImageOrientation, renderSize: CGSize, naturalSize: CGSize, fillMode: FillMode) -> CGAffineTransform {
    
    var translateX: CGFloat = 0.0
    var translateY: CGFloat = 0.0
    var rotate: CGFloat = 0.0
    var naturalSize = naturalSize
    var t: CGAffineTransform = .identity
    
    if orientation == .up || orientation == .down {
        naturalSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        rotate = orientation == .up ? 90.0 : -90
    }

    if fillMode == .fill {
        
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        scaleX = renderSize.width / naturalSize.width
        scaleY = renderSize.height / naturalSize.height
        
        switch orientation {
        case .up:
            translateX = renderSize.width / scaleX / 2 + naturalSize.width / 2
        case .down:
            translateY = renderSize.height / scaleY / 2 + naturalSize.height / 2
        default:
            translateY = renderSize.height / scaleY / 2 - naturalSize.height / 2
            translateX = (renderSize.width - naturalSize.width * scaleX) / 2 / scaleX
        }
        
        t = t.scaledBy(x: scaleX, y: scaleY)
        t = t.translatedBy(x: translateX, y: translateY)
        t = t.rotated(by: rotate.toRadians)
        
        return t
    }
    
    var scale: CGFloat = 1.0
    
    switch fillMode {
    case .aspectFill:
        scale = max(renderSize.width / naturalSize.width, renderSize.height / naturalSize.height)
        
        switch orientation {
        case .up:
            translateX = renderSize.width / scale / 2 + naturalSize.width / 2
            translateY = (renderSize.height - naturalSize.height * scale) / 2 / scale
        case .down:
            translateX = 0
            translateY = renderSize.height / scale / 2 + naturalSize.height / 2
        default:
            translateX = (renderSize.width - naturalSize.width * scale) / 2 / scale
            translateY = renderSize.height / scale / 2 - naturalSize.height / 2
        }

    case .aspectFit:
        scale = min(renderSize.width / naturalSize.width, renderSize.height / naturalSize.height)
        
        switch orientation {
        case .up:
            translateX = renderSize.width / scale / 2 + naturalSize.width / 2
            translateY = 0
        case .down:
            translateX = (renderSize.width - naturalSize.width * scale) / 2 / scale
            translateY = renderSize.height / scale / 2 + naturalSize.height / 2
        default:
            translateX = (renderSize.width - naturalSize.width * scale) / 2 / scale
            translateY = renderSize.height / scale / 2 - naturalSize.height / 2
        }
        
    default:
        break
    }
    
    t = t.scaledBy(x: scale, y: scale)
    t = t.translatedBy(x: translateX, y: translateY)
    t = t.rotated(by: rotate.toRadians)
    
    return t
}

extension FloatingPoint {
    var toRadians: Self { return self * .pi / 180 }
    var toDegrees: Self { return self * 180 / .pi }
}
