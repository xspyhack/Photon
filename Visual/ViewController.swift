//
//  ViewController.swift
//  Visual
//
//  Created by k on 2017/10/20.
//  Copyright © 2017 blessingsoft. All rights reserved.
//

import UIKit
import Photos
import Photon

class ViewController: UIViewController {
    
    lazy var editor: Editor = {
        let editor = Editor()
        editor.delegate = self
        return editor
    }()
    
    lazy var previewer: Previewer = {
        let previewer = Previewer()
        return previewer
    }()
    
    private var pickingItems: [URL] = []
    
    private var audioItems: [URL] = []
    
    private var images: [UIImage] = []
    
    private var isAddedLayer = false
    
    private var url: URL? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard let path = paths.first else {
            return nil
        }
        let filePath = "\(path)/output.mp4"
        
        let fd = FileManager.default
        if fd.fileExists(atPath: filePath) {
            try? fd.removeItem(atPath: filePath)
        }
        
        return URL(fileURLWithPath: filePath)
    }

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var thumbnailView: UIView!
    @IBOutlet weak var debugView: DebugView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        previewView.addSubview(previewer.playerView)
        
        previewer.delegate = self
        debugView.player = previewer.player
    
        load()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        print("didReceiveMemoryWarning")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewer.playerView.frame = previewView.bounds
    }
    
    @IBAction func playAction(_ sender: UIBarButtonItem) {
        guard images.count > 3, let url = url else {
            return
        }
        
        let videoSize = CGSize(width: 1080, height: 768)
        //let renderer = BlindsFrameTransitionRenderer(axis: .horizontal, count: 10)
        //let renderer = ZoomFrameRenderer(from: 1.0, to: 3.0)
        let transitionRenderer = FadeFrameTransitionRenderer()
        let generator = VideoGenerator(videoSize: videoSize, frameDuration: 30, transitionRenderer: transitionRenderer, transitionDuration: 5)
        
        do {
            try generator.generateAsynchronously(images: images, to: url) { (result) in
                switch result {
                case .success(let success):
                    if success {
                        self.save(url: url)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }
    
    @IBAction func addAsset(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum)!
        picker.videoQuality = .typeHigh
        
        picker.modalPresentationStyle = .popover
        let popover = picker.popoverPresentationController
        popover?.permittedArrowDirections = .any
        popover?.barButtonItem = navigationItem.rightBarButtonItem
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        let seconds = previewer.duration * Float64(sender.value)
        previewer.seek(to: seconds)
    }
    
    private func save(url: URL) {
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url)
            let _ = request?.placeholderForCreatedAsset
        }) { (success, error) in
            print("save to album: \(success), error: \(error)")
        }
    }
    
    private func updateThumbnaiView(asset: AVAsset) {
        thumbnailView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let duration = asset.duration.seconds
        let number = 10
        let w: CGFloat = self.view.bounds.width / CGFloat(number)
        let h: CGFloat = w * 9 / 16
        var x: CGFloat = 0
        var t: Float64 = 0
        
        var times: [Float64] = []
        for _ in 0..<number {
            t += duration / Float64(number)
            times.append(t)
        }
        
        editor.generateThumbnailAsynchronously(with: times) { [unowned self] result in
            switch result {
            case .success(let image):
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x: x, y: 0, width: w, height: h)
                imageView.backgroundColor = UIColor.gray
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                self.thumbnailView.addSubview(imageView)
                
                x += w
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        images.append(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func load() {
        let bundle = Bundle.main
        let item1 = URL(fileURLWithPath: bundle.path(forResource: "1", ofType: "M4V")!)
        let item2 = URL(fileURLWithPath: bundle.path(forResource: "2", ofType: "MOV")!)
        let item3 = URL(fileURLWithPath: bundle.path(forResource: "3", ofType: "M4V")!)
        let item4 = URL(fileURLWithPath: bundle.path(forResource: "4", ofType: "mp4")!)
        let item5 = URL(fileURLWithPath: bundle.path(forResource: "5", ofType: "mp4")!)
        let item6 = URL(fileURLWithPath: bundle.path(forResource: "6", ofType: "MOV")!)
        
//        pickingItems.append(item1)
//        pickingItems.append(item3)
        pickingItems.append(item4)
//        pickingItems.append(item5)
        pickingItems.append(item2)
        pickingItems.append(item6)
        
//        let audio1 = URL(fileURLWithPath: bundle.path(forResource: "music", ofType: "mp3")!)
//        let audio2 = URL(fileURLWithPath: bundle.path(forResource: "kid", ofType: "mp3")!)
//        let audio3 = URL(fileURLWithPath: bundle.path(forResource: "voice", ofType: "m4a")!)
//        audioItems.append(audio1)
//        audioItems.append(audio2)
//        audioItems.append(audio3)

        reload()
    }
}

extension ViewController : EditorDelegate {
    
    func reload() {
        
        let items: [VideoItem] = pickingItems.map {
            let item = VideoItem(url: $0, volume: 0.6)
            item.filter = Filter(type: .chrome)
            return item
        }
        
//        items[1].selectedRange = MediaRange.range(start: 2, duration: 3)
        
        var project = Project(videoItems: items, transitionDuration: 1.0, fillMode: .aspectFill)
        project.layers.removeAll()
        
//        project.musicItem = AudioItem(url: audioItems[1])
        
        editor.load(project: project)
    }
    
    func editor(_ editor: Editor, didLoadToPreview item: Previewable) {
        previewer.load(item: item)
        
        let layer = AnimationLayer(duration: item.composition.duration.seconds)
        editor.addLayer(layer)
        
//        let filter = Filter(type: .mono)
//        editor.setFilter(filter)
        
        updateThumbnaiView(asset: item.composition)
        
        debugView.synchronize(to: item.composition, videoComposition: item.videoComposition, audioMix: item.audioMix)
    }
    
    func editor(_ editor: Editor, didUpdateToPreview item: Previewable) {
        previewer.load(item: item)
        
        debugView.synchronize(to: item.composition, videoComposition: item.videoComposition, audioMix: item.audioMix)
    }
    
    func editor(_ editor: Editor, didFailToPreview error: Error?) {
        print(error ?? "unknow error")
    }
}

extension ViewController : PreviewerDelegate {
    
    func previewer(_ previewer: Previewer, playerViewDidPlayToEndTime: PlayerView) {
        print("preview end")
    }
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, didFailed error: Error?) {
        print(error ?? "unknow error")
    }
    
    func previewer(_ preivewer: Previewer, playerView: PlayerView, progress: Float) {
        slider.setValue(progress, animated: true)
    }
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, durationDidChange duration: Float) {
        print("duration did change \(duration)")
    }
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, statusDidChange status: PreviewerStatus) {
        print("status did change \(status)")
    }
    
    func previewer(_ previewer: Previewer, playerView: PlayerView, presentationSizeDidChange presentationSize: CGSize) {
        print("presentation size did change \(presentationSize)")
    }
}

