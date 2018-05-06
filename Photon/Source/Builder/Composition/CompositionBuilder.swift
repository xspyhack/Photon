//
//  CompositionBuilder.swift
//  Photon
//
//  Created by k on 2017/10/23.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

enum CompositionBuilderError : Error {
    case canNotAddAudioTrack
    case canNotAddVideoTrack
}

protocol CompositionBuilder {
    associatedtype C : Composition
    func build(with items: [VideoItem]) throws -> C
}
