//
//  DisplayLinkProxy.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 28/10/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

protocol DisplayLinkProtocol : class {
    
    var displayLink: CADisplayLink { get }
    
    func displayLinkUpdate(_ displaylink: CADisplayLink)
    
    /// Add the display link to the current run loop.
    func attachDisplayLink()
}

extension DisplayLinkProtocol {
    func attachDisplayLink() {
        displayLink.add(to: .current, forMode: RunLoopMode.commonModes)
    }
}

/// A proxy class to avoid a retain cycle with the display link.
class DisplayLinkProxy {
    
    /// The target exporter
    private weak var target: DisplayLinkProtocol?
    
    init(target: DisplayLinkProtocol) {
        self.target = target
    }
    
    /// Lets the target update the frame if needed.
    @objc func loop(_ sender: CADisplayLink) {
        target?.displayLinkUpdate(sender)
    }
}
