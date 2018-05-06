//
//  Project.swift
//  Photon
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

/// The edit project, it's use to load to editor.
public struct Project {
    
    /// Video clips
    public var videoItems: [VideoItem] = []
   
    /// Voiceovers
    public var audioItems: [AudioItem] = []
    
    /// Background Music
    public var musicItem: AudioItem? = nil
    
    /// Global filter on all video items
    public var filterName: String?
    public var filter: FilterProtocol? = nil
    
    /// Layers added to video
    public var layers: [LayerProtocol] = []
    
    /// Global transition duration apply to all video
    public let transitionDuration: Float64
    
    /// If ture, it will mute video item original audio track
    public let isMutedWhenVarispeed: Bool
    
    /// Fill mode, defaults aspectFill
    public let fillMode: FillMode
    
    /// Preferred output video size for all video item
    public let preferredVideoSize: CGSize = .zero
    
    /// Public init
    public init(videoItems: [VideoItem] = [],
                filterName: String? = nil,
                layers: [LayerProtocol] = [],
                transitionDuration: Float64,
                muteWhenVarispeed: Bool = false,
                fillMode: FillMode = .aspectFill) {
        self.videoItems = videoItems
        self.filterName = filterName
        self.layers = layers
        self.transitionDuration = transitionDuration
        self.isMutedWhenVarispeed = muteWhenVarispeed
        self.fillMode = fillMode
    }
}
