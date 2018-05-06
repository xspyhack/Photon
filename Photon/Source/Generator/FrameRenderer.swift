//
//  FrameRenderer.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 06/01/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import Foundation

public typealias Frame = (content: CGImage, progress: Float)

public enum ZoomType {
    case `in`
    case out
}

public enum FrameEffectType {
    case none
    case zoom(from: Float, to: Float)
    case twinkle
}

public protocol FrameRenderer {
    
    var effectType: FrameEffectType { get }
    
    func render(_ frame: Frame, using context: CGContext)
}

public extension FrameRenderer {
    
    var effectType: FrameEffectType { return .none }
    
    func render(_ frame: Frame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)
        context.concatenate(.identity)
        
        context.draw(frame.content, in: rect)
    }
}

public struct DefaultFrameRenderer : FrameRenderer {
    public init() { }
    
    public func render(_ frame: Frame, using context: CGContext) -> Void {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)
        context.concatenate(.identity)
        
        context.draw(frame.content, in: rect)
    }
}

public struct ZoomFrameRenderer : FrameRenderer {
    
    private let zoomType: ZoomType
    private let from: Float
    private let to: Float
    
    public init(from: Float, to: Float) {
        self.zoomType = from > to ? .out : .in
        self.from = from
        self.to = to
    }
    
    public var effectType: FrameEffectType { return .zoom(from: from, to: to) }
    
    public func render(_ frame: Frame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)
        context.concatenate(.identity)
        
        // draw rect
        guard case let .zoom(from, to) = effectType else {
            return
        }
        
        let frameSize = CGSize(width: frame.content.width, height: frame.content.height)
        let scale = CGFloat((to - from) * frame.progress + from)
        let scaledSize = frameSize.applying(CGAffineTransform(scaleX: scale, y: scale))
        let drawRect = CGRect(x: (frameSize.width - scaledSize.width) / 2, y: (frameSize.height - scaledSize.height) / 2, width: scaledSize.width, height: scaledSize.height)
        
        context.draw(frame.content, in: drawRect)
    }
}
