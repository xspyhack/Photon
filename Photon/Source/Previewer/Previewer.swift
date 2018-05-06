//
//  Previewer.swift
//  Photon
//
//  Created by k on 2017/10/23.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import AVFoundation

public enum PreviewerStatus {
    case unknown
    case readyToPlay
    case play
    case pause
    case playToEndTime
    case failed
}

public class Previewer : NSObject {
    
    public var isAutoPlay: Bool = true
    
    public var synchronizedLayer: AVSynchronizedLayer?
    
    public let player = AVPlayer()
   
    public lazy var previewView: PreviewView = PreviewView()
    public lazy var playerView: PlayerView = PlayerView()
    
    public private(set) var status: PreviewerStatus = .unknown
    
    public weak var delegate: PreviewerDelegate?
    
    public private(set) var presentationSize: CGSize = .zero
    
    public private(set) var currentTime: Float64 = 0.0
    
    private lazy var videoOutput: AVPlayerItemVideoOutput = {
        let attributes = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
        output.setDelegate(self, queue: self.videoOutputQueue)
        return output
    }()
    
    private let videoOutputQueue = DispatchQueue(label: "com.blessingsoft.photon.videoOutput")
    
    private var isObserving = false
    
    private var lastTimestamp: CFTimeInterval = 0
    
    private var currentItem: Previewable?
    
    private struct Constant {
        static let oneFrameDuration: TimeInterval = 0.03
        
        static var playerItemContext = 0
        
        static var timeObserverToken: Any?
        
        static var playerStatus = 0
        static var playerStatusKey = "status"
        
        static var playerItemStatus = 0
        static var playerItemStatusKey = "currentItem.status"
    }
    
    /// Tracks whether the display link is initialized.
    private var displayLinkInitialized: Bool = false
    
    lazy var displayLink: CADisplayLink = { [unowned self] in
        self.displayLinkInitialized = true
        let link = CADisplayLink(target: DisplayLinkProxy(target: self), selector: #selector(DisplayLinkProxy.loop(_:)))
        link.add(to: .current, forMode: RunLoopMode.commonModes)
        link.isPaused = true
        return link
    }()
    
    deinit {
        stop()
    }
}

// MARK: - Public Method

extension Previewer {
    
    public func load(item: Previewable, seekTo seconds: Float64 = 0) {
        currentItem = item
        
        player.pause()
        stopObserving(player: player)
        
        let asset = item.composition
        
        load(asset: asset)
        load(videoCompostion: item.videoComposition)
        load(audioMix: item.audioMix)
        load(filter: item.filter)
        load(layer: item.overlayLayer, videoSize:item.videoComposition.renderSize)
        
        seek(to: seconds)
        
        startObserving(player: player)
    }
    
    public func play() {
        addTimeObserver(from: player)
        player.play()
        displayLink.isPaused = false
    }
    
    public func pause() {
        removeTimeObserver(from: player)
        player.pause()
        displayLink.isPaused = true
    }
    
    public func stop() {
        removeTimeObserver(from: player)
        stopObserving(player: player)
        player.pause()
        displayLink.isPaused = true
    }
    
    public func seek(to seconds: Float64) {
        guard let playerItem = player.currentItem else {
            return
        }
        
        let time = CMTime(seconds: seconds, preferredTimescale: playerItem.asset.duration.timescale)
        guard time.isValid else {
            assert(false, "time is not valid")
            return
        }

        player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
}

// MARK: - Player

extension Previewer {
    
    public var duration: Float64 {
        
        guard player.status == .readyToPlay, let currentItem = player.currentItem else {
            return 0.0
        }
        
        return currentItem.duration.seconds
    }
    
    public var isMuted: Bool {
        get {
            return player.isMuted
        }
        set {
            player.isMuted = newValue
        }
    }
    
    public var volume: Float {
        get {
            return player.volume
        }
        set {
            player.volume = newValue
        }
    }
}

// MARK: - Load

extension Previewer {
    
    private func load(asset: AVAsset, autoPlay: Bool = true) {
        isAutoPlay = autoPlay
        
        // Remove video output from old item, if any.
        player.currentItem?.remove(videoOutput)
        
        let item = AVPlayerItem(asset: asset)
        
        let assetKeysToLoad = ["tracks", "duration", "playable"]
        
        asset.loadValuesAsynchronously(forKeys: assetKeysToLoad) { [unowned self] in
            for item in assetKeysToLoad {
                var error: NSError?
                if asset.statusOfValue(forKey: item, error: &error) == .failed {
                    print("Key value loading failed for key: \(item) with error: \(error!)")
                    return
                }
            }
            
            guard asset.isPlayable else {
                print("Asset is not playable")
                return
            }
            
            item.add(self.videoOutput)
            self.player.replaceCurrentItem(with: item)
            self.videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: Constant.oneFrameDuration)
            
            if autoPlay {
                self.play()
            }
        }
    }
    
    private func load(videoCompostion: AVVideoComposition) {
        guard let currentItem = player.currentItem else {
            return;
        }
        
        currentItem.videoComposition = videoCompostion
    }
    
    private func load(audioMix: AVAudioMix) {
        guard let currentItem = player.currentItem else {
            return;
        }
        
        currentItem.audioMix = audioMix
    }
    
    private func load(filter: FilterProtocol?) {
        previewView.filter = filter?.filter
    }
    
    private func load(layer: CALayer?, videoSize: CGSize) {
        guard let layer = layer, let playerItem = player.currentItem else {
            return
        }
        
        if let syncLayer = synchronizedLayer {
            syncLayer.removeFromSuperlayer()
            self.synchronizedLayer = nil
        }
        
        let frame = layerFrame(playerSize: self.playerView.bounds.size, videoSize: videoSize)
        let scaleWidth = frame.width / layer.bounds.width
        let scaleHeight = frame.height / layer.bounds.height
        
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        layer.transform = CATransform3DScale(layer.transform, scaleWidth, scaleHeight, 1.0);
        
        synchronizedLayer = AVSynchronizedLayer(playerItem: playerItem)
        synchronizedLayer?.frame = frame
        synchronizedLayer?.addSublayer(layer)
        playerView.layer.addSublayer(synchronizedLayer!)
    }
    
    private func layerFrame(playerSize: CGSize, videoSize: CGSize) -> CGRect {
        
        let playerRatio = playerSize.width / playerSize.height
        let videoRatio = videoSize.width / videoSize.height
        
        let frame: CGRect
        if playerRatio >= videoRatio {
            let height = playerSize.height
            let width = videoRatio * height
            frame = CGRect(x: (playerSize.width - width) / 2, y: 0, width: width, height: height)
        } else {
            let width = playerSize.width
            let height = width / videoRatio
            frame = CGRect(x: 0, y: (playerSize.height - height) / 2, width: width, height: height)
        }
        
        return frame
    }
}

// MARK: - Observation

extension Previewer {
 
    private func startObserving(player: AVPlayer) {
        guard !isObserving else { return }
        
        player.addObserver(self, forKeyPath: Constant.playerStatusKey, options: .new, context: &Constant.playerStatus)
        player.addObserver(self, forKeyPath: Constant.playerItemStatusKey, options: .new, context: &Constant.playerItemStatus)
        
        if let currentItem = player.currentItem {
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        
        isObserving = true
    }
    
    private func stopObserving(player: AVPlayer) {
        guard isObserving else { return }
        
        player.removeObserver(self, forKeyPath: Constant.playerStatusKey, context: &Constant.playerStatus)
        player.removeObserver(self, forKeyPath: Constant.playerItemStatusKey, context: &Constant.playerItemStatus)
        
        if let currentItem = player.currentItem {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
        
        isObserving = false
    }
    
    private func removeTimeObserver(from player: AVPlayer) {
        
        if let timeObserverToken = Constant.timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        
        Constant.timeObserverToken = nil
    }
    
    private func addTimeObserver(from player: AVPlayer) {
        
        removeTimeObserver(from: player)
        
        player.actionAtItemEnd = .none
        let interval = CMTime(seconds: 0.1, preferredTimescale: Defaults.preferredTimescale)
        Constant.timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let sSelf = self else {
                return
            }
            
            // sync time progress
            var seconds = time.seconds
            if seconds.isInfinite {
                seconds = 0
            }
            
            self?.delegate?.previewer(sSelf, playerView: sSelf.playerView, progress: min(1.0, Float(seconds / sSelf.duration)))
        }
    }
    
    
    @objc private func playerItemDidPlayToEndTime(_ notification: Notification) {
        delegate?.previewer(self, playerViewDidPlayToEndTime: playerView)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let context = context else { return }
        
        switch context {
            
        case &Constant.playerStatus, &Constant.playerItemStatus:
            
            guard let playerItem = player.currentItem else { return }
            
            if case .readyToPlay = playerItem.status, case .readyToPlay = player.status {
                delegate?.previewer(self, playerView: playerView, statusDidChange: .readyToPlay)
            } else if case .failed = playerItem.status {
                delegate?.previewer(self, playerView: playerView, didFailed: playerItem.error ?? player.error)
            }
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - AVPlayerItemOutputPullDelegate

extension Previewer: AVPlayerItemOutputPullDelegate {
    
    public func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
        // Restart display link.
        DispatchQueue.main.async {
            self.displayLink.isPaused = false
        }
    }
    
    public func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {
        // video layer flush
        DispatchQueue.main.async {
            self.playerView.videoLayer.controlTimebase = self.player.currentItem!.timebase
            self.playerView.videoLayer.flush()
        }
    }
}

// MARK: - DisplayLinkProtocol

extension Previewer: DisplayLinkProtocol {
    
    func displayLinkUpdate(_ displayLink: CADisplayLink) {
        /*
         The callback gets called once every Vsync.
         Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
         This pixel buffer can then be processed and later rendered on screen.
         */

        // Calculate the nextVsync time which is when the screen will be refreshed next.
        let nextVSync = displayLink.timestamp + displayLink.duration
        let itemTime = videoOutput.itemTime(forHostTime: nextVSync)
        
        var presentationItemTime = kCMTimeZero
        
        guard videoOutput.hasNewPixelBuffer(forItemTime: itemTime), let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &presentationItemTime)  else {
            
            if displayLink.timestamp - lastTimestamp > 0.5 {
                displayLink.isPaused = true
                videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: Constant.oneFrameDuration)
            }
            
            return
        }
        
        lastTimestamp = displayLink.timestamp
        playerView.display(pixelBuffer: pixelBuffer, atTime: presentationItemTime)
        
        //previewView.display(pixelBuffer: pixelBuffer)
    }
}

// MARK: - PreviewerDelegate

public protocol PreviewerDelegate : class {
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, didFailed error: Error?)
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, statusDidChange status: PreviewerStatus)
    
    func previewer(_ preivewer: Previewer, playerView: PlayerView, progress: Float)
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, durationDidChange duration: Float)
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, presentationSizeDidChange presentationSize: CGSize)
    
    func previewer(_ previewer: Previewer, playerViewDidPlayToEndTime: PlayerView)
}
