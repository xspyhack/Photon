//
//  Editor.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 26/10/2017.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public class Editor {
    
    public weak var delegate: EditorDelegate?
    
    ///
    private var transitionDuration: CMTime = kCMTimeZero
    private var fillMode: FillMode = .aspectFill
    private var preferredVideoSize: CGSize = .zero
    private var musicAsset: AVAsset?
    private var musicTrack: AVMutableCompositionTrack?
    
    public private(set) var project: Project? = nil
    public private(set) var layers: [LayerProtocol] = []
    public private(set) var filter: FilterProtocol?
    
    public private(set) var composition: AVMutableComposition?
    public private(set) var videoComposition: AVMutableVideoComposition?
    public var audioMix: AVMutableAudioMix { return audioMixBuilder.audioMix  }
    
    private let audioMixBuilder = AudioMixBuilder()
    
    public init() {}
}


// MARK: - Project

public extension Editor {
    
    public func load(project: Project) {
        self.project = project
        
        transitionDuration = CMTime(value: Int64(project.transitionDuration * Float64(Defaults.preferredTimescale)), timescale: Defaults.preferredTimescale)
        fillMode = project.fillMode
        layers.removeAll()
        layers.append(contentsOf: project.layers)
        
        var videoBuilder = VideoBuilder(transitionDuration: project.transitionDuration)
        videoBuilder.isMutedWhenVarispeed = project.isMutedWhenVarispeed
        videoBuilder.transitionType = .dissolve
        
        videoBuilder.build(videoItems: project.videoItems) { [unowned self] result in
            switch result {
            case .success(let videoItems):
                self.build(with: videoItems)
                if let musicItem = project.musicItem {
                    self.mixMusicItem(musicItem)
                }
                
                self.didLoadToPreview()
            case .failure(let error):
                self.delegate?.editor(self, didFailToPreview: error)
            }
        }
    }
}


// MARK: - Video

public extension Editor {
    
    public func select(ranges: [MediaRange], at index: Int) {
        
        guard let project = project, let videoItem = project.videoItems.safe[index] else {
            return
        }
        
        videoItem.selectedRange = ranges.first // fixme
        
        load(project: project)
    }
    
    public func select(range: MediaRange, at index: Int) {
        select(ranges: [range], at: index)
    }
    
    public func setVideoItemVolume(_ volume: Float, at index: Int) {
        
    }
    
    public func getVideoItemVolume(at index: Int) {
        
    }
}


// MARK: - Filter

public extension Editor {
    
    public func setFilter(_ filter: FilterProtocol) {
        
        didUpdateToPreview()
    }
}


// MARK: - Layer

public extension Editor {
    
    public func addLayer(_ layer: LayerProtocol) {
        insertLayer(layer, at: layers.count)
    }
    
    public func addLayers(_ layers: [LayerProtocol]) {
        layers.forEach { layer in
            if let index = self.layers.index(where: { $0.layer == layer.layer }) {
                self.layers.remove(at: index)
            }
        }
        
        self.layers.append(contentsOf: layers)
        
        didUpdateToPreview()
    }
    
    public func insertLayer(_ layer: LayerProtocol, at index: Int) {
        if let index = layers.index(where: { $0.layer == layer.layer }) {
            layers.remove(at: index)
        }
        
        layers.append(layer)
        
        didUpdateToPreview()
    }
    
    public func removeLayer(_ layer: LayerProtocol, at index: Int) {
        guard index < layers.count else {
            return
        }
        
        layers.remove(at: index)
        
        didUpdateToPreview()
    }
    
    public func removeAllLayers() {
        layers.removeAll()
        
        didUpdateToPreview()
    }
    
    private func overlayLayer(with layers: [LayerProtocol], renderSize: CGSize) -> CALayer? {
        guard !layers.isEmpty else {
            return nil
        }
        
        let overlay = CALayer()
        overlay.frame = CGRect(origin: .zero, size: renderSize)
        overlay.masksToBounds = true
        
        layers.forEach {
            overlay.addSublayer($0.layer)
        }
        
        return overlay
    }
    
    private func animationTool(with overlayLayer: CALayer) -> AVVideoCompositionCoreAnimationTool {
        let animationLayer = CALayer()
        animationLayer.frame = overlayLayer.bounds
        
        let videoLayer = CALayer()
        videoLayer.frame = overlayLayer.bounds
        
        animationLayer.addSublayer(videoLayer)
        animationLayer.addSublayer(overlayLayer)
        animationLayer.isGeometryFlipped = true
        
        return AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: animationLayer)
    }
}


// MARK: - Music

public extension Editor {
    
    public func mixMusicItem(_ item: AudioItem) {
        addMusicMix(with: item.asset)
        
        project?.musicItem = item
        
        didUpdateToPreview()
    }
    
    public func removeMusicItem() {
        removeMusicMix()
        
        didUpdateToPreview()
    }
    
    public func mixMusicItem(with url: URL) {
        let item = AudioItem(url: url)
        
        mixMusicItem(item)
    }
    
    private func addMusicMix(with audioAsset: AVAsset) {
        guard !audioAsset.tracks(withMediaType: .audio).isEmpty, let composition = composition, let musicTrack = musicTrack else {
            return
        }
        
        let duration = composition.duration
        let timeRange = CMTimeRange(start: kCMTimeZero, duration: duration) // total duration
        
        guard let audioTrack = audioAsset.tracks(withMediaType: .audio).first else {
            return
        }
    
        var atTime = kCMTimeZero
        
        if duration < CMTime(seconds: 3, preferredTimescale: 1) {
            try? musicTrack.insertTimeRange(timeRange, of: audioTrack, at: kCMTimeZero)
            
            let automation = VolumeAutomation(timeRange: timeRange, start: 1.0, end: 1.0)
            AudioMixBuilder().add(audioTrack: musicTrack, with: [automation])
            
            return
        }
        
        var automations: [VolumeAutomation] = []
        
        var insertedTime = kCMTimeZero
        while insertedTime < timeRange.duration {
            // 音频时间小于视频长度的时候，要插入多段
            // insert = min(remainder, next)
            
            let remainder = timeRange.duration - insertedTime
            let next = audioTrack.timeRange.duration
            let insertTimeRange = remainder <= next ? CMTimeRange(start: kCMTimeZero, duration: remainder) : audioTrack.timeRange
            
            try? musicTrack.insertTimeRange(insertTimeRange, of: audioTrack, at: atTime)
            
            insertedTime = insertedTime + insertTimeRange.duration
            
            // 默认 1s 的淡入淡出时间
            let timescale = duration.timescale
            let fadeInTime = CMTime(seconds: 1.0, preferredTimescale: timescale)
            let fadeInRange = CMTimeRange(start: atTime, duration: fadeInTime)
            let fadeOutTime = CMTime(seconds: 1.0, preferredTimescale: timescale)
            let fadeOutRange = CMTimeRange(start: insertedTime - fadeOutTime, duration: fadeOutTime)
        
            let fadeInAutomation = VolumeAutomation(timeRange: fadeInRange, start: 0.0, end: 1.0)
            let fadeOutAutomation = VolumeAutomation(timeRange: fadeOutRange, start: 1.0, end: 0.0)
            
            automations.append(fadeInAutomation)
            automations.append(fadeOutAutomation)
            
            atTime = atTime + audioTrack.timeRange.duration
        }
 
        AudioMixBuilder().add(audioTrack: musicTrack, with: automations)
    }
    
    private func removeMusicMix() {
        guard let musicTrack = musicTrack else {
            return
        }
        
        composition?.removeTrack(musicTrack)
        self.musicTrack = nil
    }
}


// MARK: - Voice Over

public extension Editor {
    
    public func addVoiceoverItem(_ item: AudioItem) {
        
    }
    
    public func removeVoiceoverItem(_ item: AudioItem) {
        
    }
}


// MARK: - Thumbnail

public extension Editor {
   
    @discardableResult
    public func generateThumbnailAsynchronously(with times: [Float64], maximumSize: CGSize? = nil, completion: @escaping (Result<UIImage>) -> Void) -> AVAssetImageGenerator? {
        
        guard let asset = composition, !times.isEmpty else {
            return nil
        }
        
        let scaledTimes = times.map { time -> NSValue in
            var scaledTime = asset.duration
            scaledTime.value = CMTimeValue(time * Float64(scaledTime.timescale))
            return NSValue(time: scaledTime)
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        if let maximumSize = maximumSize {
            generator.maximumSize = maximumSize
        }
        generator.videoComposition = videoComposition
        generator.appliesPreferredTrackTransform = true
        
        generator.generateCGImagesAsynchronously(forTimes: scaledTimes) { (requestedTime, cgImage, actualTime, result, error) in
           
            switch result {
            case .succeeded:
                guard let cgImage = cgImage else {
                    DispatchQueue.main.async {
                        completion(.failure(error ?? PhotonError.unknown))
                    }
                    return
                }
                
                let thumbnail = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    completion(.success(thumbnail))
                }
            default:
                DispatchQueue.main.async {
                    completion(.failure(error ?? PhotonError.unknown))
                }
            }
        }
        
        return generator
    }
}


// MARK: - Context

public extension Editor {
    
    public var renderSize: CGSize {
        return videoComposition?.renderSize ?? .zero
    }
    
    public var naturalSize: CGSize {
        return composition?.naturalSize ?? .zero
    }
    
    public var previewerItem: PreviewerItem? {
        guard let composition = composition, let videoComposition = videoComposition else {
            return nil
        }
        
        let layer = overlayLayer(with: layers, renderSize: renderSize)
        
        let item = PreviewerItem(composition: composition, videoComposition: videoComposition, audioMix: audioMix, filter: filter, overlayLayer: layer)

        return item
    }
    
    public var exporterItem: Exportable? {
        
        guard let composition = composition, let videoComposition = videoComposition else {
            return nil
        }
        
        var animationTool: AVVideoCompositionCoreAnimationTool? = nil
        if let layer = overlayLayer(with: layers, renderSize: renderSize) {
            animationTool = self.animationTool(with: layer)
        }
        
        let item = ExporterItem(composition: composition, videoComposition: videoComposition, audioMix: audioMix, filter: nil, animationTool: animationTool)
        
        return item
    }
}


// MARK: - Private

extension Editor {
    
    private func didLoadToPreview() {
        DispatchQueue.main.async {
            guard let item = self.previewerItem else {
                self.delegate?.editor(self, didFailToPreview: PhotonError.failedToLoadProject)
                return
            }
            
            self.delegate?.editor(self, didLoadToPreview: item)
        }
    }
    
    private func didUpdateToPreview() {
        DispatchQueue.main.async {
            guard let item = self.previewerItem else {
                self.delegate?.editor(self, didFailToPreview: PhotonError.failedToLoadProject)
                return
            }
            
            self.delegate?.editor(self, didUpdateToPreview: item)
        }
    }
    
    private func didFail(with error: Error) {
        DispatchQueue.main.async {
            self.delegate?.editor(self, didFailToPreview: error)
        }
    }
    
    private func build(with videoItems: [VideoItem]) {
        do {
            //let composition = try NeutrinoCompositionBuilder().build(with: videoItems)
            
            //var videoCompositionBuilder = NeutrinoVideoCompositionBuilder()
            //videoCompositionBuilder.fillMode = fillMode
            //videoCompositionBuilder.preferredVideoSize = preferredVideoSize

            //let videoComposition = videoCompositionBuilder.build(in: composition)

            let composition = try ElectronCompositionBuilder(transitionDuration: transitionDuration).build(with: videoItems)
            
            var videoCompositionBuilder = ElectronVideoCompositionBuilder()
            videoCompositionBuilder.fillMode = fillMode
            videoCompositionBuilder.preferredVideoSize = preferredVideoSize
            videoCompositionBuilder.compositorClass = CrossDissolveVideoCompositor.self
            
            let videoComposition = videoCompositionBuilder.build(in: composition)
            
//            audioMixBuilder.build(in: composition)
            
            // prepare music track
            self.musicTrack = composition.composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            self.composition = composition.composition
            self.videoComposition = videoComposition
        } catch {
            didFail(with: error)
        }
    }
}


public protocol EditorDelegate : class {
    
    func editor(_ editor: Editor, didLoadToPreview item: Previewable)
    
    func editor(_ editor: Editor, didUpdateToPreview item: Previewable)
    
    func editor(_ editor: Editor, didFailToPreview error: Error?)
}
