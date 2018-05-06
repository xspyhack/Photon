//
//  Exporter.swift
//  Photon
//
//  Created by k on 2017/10/23.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

/// The video exporter
public class Exporter {
    
    /// True for exporting
    public private(set) var isExporting: Bool = false

    /// Specifies the progress of the export on a scale from 0 to 1.0
    public private(set) var progress: Float = 0
    
    /// Indicates the URL of the export session's output
    public var outputURL: URL?
    
    /// Export event callback delegate
    public weak var delegate: ExporterDelegate?
   
    /// Output video preset
    public var preset: AVOutputSettingsPreset = .preset1280x720
   
    /// Exportable media item.
    private let item: Exportable
    
    /// Tracks whether the display link is initialized.
    private var displayLinkInitialized: Bool = false
    
    lazy var displayLink: CADisplayLink = { [unowned self] in
        self.displayLinkInitialized = true
        let link = CADisplayLink(target: DisplayLinkProxy(target: self), selector: #selector(DisplayLinkProxy.loop(_:)))
        attachDisplayLink()
        link.isPaused = true
        return link
    }()
    
    private lazy var session: AVAssetExportSession? = {
        let session = AVAssetExportSession(asset: self.item.composition, presetName: AVAssetExportPresetHighestQuality)
        session?.outputFileType = .mp4
        session?.shouldOptimizeForNetworkUse = true
        return session
    }()
    
    public init(item: Exportable, outputURL: URL? = nil) {
        self.item = item
        self.outputURL = outputURL
    }
    
    public func begin() {
        guard let session = session else {
            return
        }
        
        isExporting = true
        
        session.outputURL = outputURL
        session.audioMix = item.audioMix
        session.videoComposition = item.videoComposition
        session.exportAsynchronously { [unowned self] in
            self.isExporting = false
            
            switch session.status {
            case .completed:
                self.delegate?.exporterDidFinish(self)
            case .cancelled:
                self.delegate?.exporterDidCancel(self)
            case .failed:
                self.delegate?.exporter(self, didFail: session.error)
            default:
                ()
            }
        }
        
        resume()
    }
    
    public func cancel() {
        guard let session = session else {
            return
        }
        
        session.cancelExport()
        pause()
    }
    
    // MARK: - For progress
    
    func resume() {
        displayLink.isPaused = false
    }
    
    func pause() {
        displayLink.isPaused = true
    }
    
    deinit {
        if displayLinkInitialized {
            displayLink.invalidate()
        }
    }
}

extension Exporter: DisplayLinkProtocol {
    
    func displayLinkUpdate(_ displayLink: CADisplayLink) {
        guard let session = session else {
            return
        }
        
        switch session.status {
        case .exporting:
            progress = session.progress
            delegate?.exporter(self, progress: progress)
        default:
            isExporting = false
        }
    }
}

public protocol ExporterDelegate : class {
    
    func exporter(_ exporter: Exporter, progress: Float)
    
    func exporterDidFinish(_ exporter: Exporter)
    
    func exporterDidCancel(_ exporter: Exporter)
    
    func exporter(_ exporter: Exporter, didFail error: Error?)
}
