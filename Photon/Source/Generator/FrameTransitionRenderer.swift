//
//  FrameTransitionRenderer.swift
//  Photon
//
//  Created by k on 2017/11/8.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

public enum Direction : UInt {
    case top
    case left
    case bottom
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

public enum Axis : UInt {
    case horizontal
    case vertical
}

public enum FrameTransitionType {
    case none
    case dissolve // 渐变
    case fade // 渐变
    case blinds(Axis, UInt) // 百叶窗
    case push(Direction) // 推入
    case wipe // 划变，擦除
}

public struct TransitionFrame {
    let current: Frame
    let previous: Frame?
    let next: Frame?
    
    let progress: Float
}

public protocol FrameTransitionRenderer {
    
    var transitionType: FrameTransitionType { get }
    
    func render(_ frame: TransitionFrame, using context: CGContext)
}

public extension FrameTransitionRenderer {
    
    var transitionType: FrameTransitionType { return .none }
    
    func render(_ frame: TransitionFrame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)
        context.concatenate(.identity)
        
        context.draw(frame.current.content, in: rect)
    }
}

public struct DissolveFrameTransitionRenderer : FrameTransitionRenderer {
    
    public var transitionType: FrameTransitionType { return .dissolve }
    
    public init() {}
    
    public func render(_ frame: TransitionFrame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        // current frame 
        context.draw(frame.current.content, in: rect)
        
        // next frame
        guard let next = frame.next else {
            return
        }
        
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.setAlpha(CGFloat(frame.progress))
        context.draw(next.content, in: rect)
        context.endTransparencyLayer()
    }
}

public struct FadeFrameTransitionRenderer : FrameTransitionRenderer {
    
    public var transitionType: FrameTransitionType { return .fade }
    
    public init() {}
    
    public func render(_ frame: TransitionFrame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        // current frame
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.setAlpha(CGFloat(1 - frame.progress))
        context.draw(frame.current.content, in: rect)
        
        // next frame
        guard let next = frame.next else {
            return
        }
        
        context.setAlpha(CGFloat(frame.progress))
        context.draw(next.content, in: rect)
        context.endTransparencyLayer()
    }
}

public struct PushFrameTransitionRender : FrameTransitionRenderer {
    
    private let direction: Direction
    
    public init(direction: Direction) {
        self.direction = direction
    }
    
    public var transitionType: FrameTransitionType { return .push(direction) }
    
    public func render(_ frame: TransitionFrame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        // current frame
        context.draw(frame.current.content, in: rect)
        
        // next frame
        guard let next = frame.next else {
            return
        }
        
        guard case .push(let direction) = transitionType else {
            return
        }
        
        let offset = self.offset(in: rect, progress: CGFloat(frame.progress), direction: direction)
        let nextRect = rect.offsetBy(dx: offset.x, dy: offset.y)
        context.draw(next.content, in: nextRect)
    }
    
    private func offset(in rect: CGRect, progress: CGFloat, direction: Direction) -> CGPoint {
        switch direction {
        case .top:
            return CGPoint(x: 0, y: rect.height * (1 - progress))
        case .left:
            return CGPoint(x: rect.width * (1 - progress), y: 0)
        case .bottom:
            return CGPoint(x: 0, y: rect.height * progress)
        case .right:
            return CGPoint(x: rect.width * progress, y: 0)
        case .topLeft:
            return CGPoint(x: rect.width * (1 - progress), y: rect.height * (1 - progress))
        case .topRight:
            return CGPoint(x: rect.width * progress, y: rect.height * (1 - progress))
        case .bottomLeft:
            return CGPoint(x: rect.width * (1 - progress), y: rect.height * progress)
        case .bottomRight:
            return CGPoint(x: rect.width * progress, y: rect.height * progress)
        }
    }
}

public struct WipeFrameTransitionRenderer : FrameTransitionRenderer {
    
    public var transitionType: FrameTransitionType { return .wipe }
    
    public init() {}
    
    public func render(_ frame: TransitionFrame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        // current frame
        context.draw(frame.current.content, in: rect)
        
        // next frame
        guard let next = frame.next else {
            return
        }
        
        context.draw(next.content, in: rect)
    }
}

public struct BlindsFrameTransitionRenderer : FrameTransitionRenderer {
    
    private let axis: Axis
    private let count: UInt
    
    public init(axis: Axis, count: UInt) {
        self.axis = axis
        self.count = count
    }
    
    public var transitionType: FrameTransitionType { return .blinds(axis, count) }
    
    public func render(_ frame: TransitionFrame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        // current frame
        context.draw(frame.current.content, in: rect)
        
        // next frame
        guard let next = frame.next else {
            return
        }
        
        guard case .blinds(let axis, let count) = transitionType else {
            return
        }
        
        switch axis {
        case .horizontal:
            let width = rect.width / CGFloat(count * 2 - 1) * CGFloat(1 + frame.progress)
            let gap = (rect.width - CGFloat(count) * width) / CGFloat(count - 1)
            
            for i in 0..<count {
                let rect = CGRect(x: (width + gap) * CGFloat(i), y: 0, width: width, height: rect.height)
                if let img = next.content.cropping(to: rect) {
                    context.draw(img, in: rect)
                }
            }
        case .vertical:
            let height = rect.height / CGFloat(count * 2 - 1) * CGFloat(1 + frame.progress)
            let gap = (rect.height - CGFloat(count) * height) / CGFloat(count - 1)
            
            for i in 0..<count {
                let rect = CGRect(x: 0, y: (height + gap) * CGFloat(i), width: rect.width, height: height)
                if let img = next.content.cropping(to: rect) {
                    let ctmRect = CGRect(x: 0, y: (height + gap) * CGFloat(count - i - 1), width: rect.width, height: height)
                    context.draw(img, in: ctmRect)
                }
            }
        }
    }
}

public struct TwinkleFrameTransitionRenderer : FrameTransitionRenderer {
    
    public init() {}
    
    public func render(_ frame: TransitionFrame, using context: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        
        context.clear(rect)
        
        let drawRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        context.draw(frame.current.content, in: drawRect)
    }
}
