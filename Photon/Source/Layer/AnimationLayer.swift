//
//  AnimationLayer.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 02/12/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public struct AnimationLayer : LayerProtocol {
    
    let duration: TimeInterval
    
    public init(duration: TimeInterval) {
        self.duration = duration
    }
    
    public var layer: CALayer {
        
        let size = CGSize(width: 200, height: 200)
        let layer = ProgressLayer()
        layer.frame = CGRect(origin: CGPoint(x: 400, y: 300), size: size)
        layer.backgroundColor = UIColor.red.withAlphaComponent(0.3).cgColor
        layer.cornerRadius = size.width / 2
        
        let anim = CABasicAnimation(keyPath: #keyPath(ProgressLayer.progress))
        anim.fromValue = 0.0
        anim.toValue = 1.0
        anim.duration = duration
        anim.beginTime = AVCoreAnimationBeginTimeAtZero
        anim.isRemovedOnCompletion = false
        
        layer.add(anim, forKey: "anim")
        
        return layer
    }
}

class ProgressLayer : CALayer {
    
    @objc var progress: CGFloat = 0.0
    
    override class func needsDisplay(forKey key: String) -> Bool {
        guard key == "progress" else {
            return super.needsDisplay(forKey: key)
        }
        
        return true
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        UIGraphicsPushContext(ctx)
        
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        ctx.setLineWidth(5.0)
        ctx.setStrokeColor(UIColor.green.cgColor)
        ctx.addArc(center: center, radius: bounds.width / 2 - 10, startAngle: 0, endAngle: 2 * progress * CGFloat.pi, clockwise: false)
        ctx.strokePath()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6.0
        paragraphStyle.alignment = .center
        
        let font = UIFont.systemFont(ofSize: 30.0)
        let attributes: [NSAttributedStringKey: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: UIColor.white,
            ]
        
        let size = CGSize(width: 100, height: 40)
        let rect = CGRect(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2, width: size.width, height: size.height)
        let text = progress.format(f: ".2") as NSString
        text.draw(in: rect, withAttributes: attributes)
        
        UIGraphicsPopContext()
    }
}

extension CGFloat {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
