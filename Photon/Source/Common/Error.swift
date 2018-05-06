//
//  Error.swift
//  Photon
//
//  Created by k on 2017/10/23.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import Foundation

public enum PhotonError: Error {
    case unknown
    
    case destinationNotFound(url: URL)
    
    case invalidFormat
    
    case segmentsEmpty
    
    case canNotAddOutput
    case canNotAddInput
    case activeFormatInvalid
    
    case fpsNotSupported(fps: Int)
    
    case invalidVideoComposition
    
    case canNotAddAudioTrack
    case canNotAddVideoTrack
    
    case failedToLoadProject
}

extension PhotonError : LocalizedError {
    
    public var localizedDescription: String {
        switch self {
        case .unknown:
            return "Unknown error"
        case .destinationNotFound(let url):
            return "The temp file destination \(url) could not be created or found"
        case .invalidFormat:
             return "The source file does not appear to be a valid format"
        case .canNotAddInput:
            return "AssetWriter can not add input"
        case .canNotAddOutput:
            return "AssetReader can not add output"
        case .activeFormatInvalid:
            return "Device activeFormat invalid"
        case .fpsNotSupported(let fps):
            return "FPS \(fps) is not supported"
        case .invalidVideoComposition:
            return "Invalid VideoComposition"
        case .canNotAddAudioTrack:
            return "Invalid VideoComposition"
        case .canNotAddVideoTrack:
            return "Invalid VideoComposition"
        case .failedToLoadProject:
            return "Failed to load project"
        case .segmentsEmpty:
            return "The segments is empty"
        }
    }
}
