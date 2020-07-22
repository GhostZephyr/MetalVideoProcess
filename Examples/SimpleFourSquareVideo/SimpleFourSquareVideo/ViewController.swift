//
//  ViewController.swift
//  SimpleFourSquareVideo
//
//  Created by RenZhu Macro on 2020/7/3.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import AVFoundation
import MetalVideoProcess

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var timeLabel: UILabel!
    var player: MetalVideoProcessPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "cute", withExtension: "mp4")!)
        let asset2 = AVAsset(url: Bundle.main.url(forResource: "out", withExtension: "mp4")!)
        let asset3 = AVAsset(url: Bundle.main.url(forResource: "movie", withExtension: "mov")!)
        let asset4 = AVAsset(url: Bundle.main.url(forResource: "movie3", withExtension: "mp4")!)
        
        let item1 = MetalVideoEditorItem(asset: asset1, isMute: true)
        let item2 = MetalVideoEditorItem(asset: asset2, isMute: true)
        
        let item3 = MetalVideoEditorItem(asset: asset3, isMute: true)
        let item4 = MetalVideoEditorItem(asset: asset4, isMute: true)
        
        item2.resource.selectedTimeRange = item2.timeRange
        item3.resource.selectedTimeRange = item2.timeRange
        item4.resource.selectedTimeRange = item2.timeRange
        let backgroundFrame = self.renderView.frame
        let backgroundSize = CGSize(width: backgroundFrame.size.width * 1.5,
                                    height: backgroundFrame.size.height * 1.5)
        MetalVideoProcessBackground.canvasSize = backgroundSize
        
        
        let transform1 = MetalVideoProcessTransformFilter()
        let transform2 = MetalVideoProcessTransformFilter()
        let transform3 = MetalVideoProcessTransformFilter()
        let transform4 = MetalVideoProcessTransformFilter()
        
     
    
        
        transform1.stretchType = .aspectToFit
        transform1.roi = CGRect(x: 0.1, y: 0.1,
                                width: 0.8,
                                height: 0.8)
        
        transform2.stretchType = .aspectToFit
        transform2.roi = CGRect(x: 0.0, y: 0.1, width: 0.8, height: 0.8)
////
        transform3.stretchType = .aspectToFit
        transform3.roi = CGRect(x: 0.5, y: 0.6, width: 0.5, height: 0.5)
//
        transform4.stretchType = .aspectToFit
        transform4.roi = CGRect(x: 0.0, y: -0.25, width: 0.75, height: 0.75)
        
        do {
            let editor = try MetalVideoEditor(videoItems: [item1],
                                              overlayItems: [item2, item3, item4],
                                              customVideoCompositorClass: MetalVideoProcessCompositor.self)
            let playerItem = editor.buildPlayerItem()
            
            let background = MetalVideoProcessBackground(trackID: item1.trackID)
            background.setBackgroundType(type: .Blur)
            background.canvasSizeType = .Type720p
            background.aspectRatioType = .Ratio9_16
            
            let player = try MetalVideoProcessPlayer(playerItem: playerItem)
            
            player.addTarget(background, atTargetIndex: nil, trackID: item1.trackID, targetTrackId: 0)
            
            player.addTarget(transform1, trackID: item1.trackID, targetTrackId: item1.trackID)
            player.addTarget(transform2, trackID: item2.trackID, targetTrackId: item2.trackID)
            player.addTarget(transform3, trackID: item3.trackID, targetTrackId: item3.trackID)
            player.addTarget(transform4, trackID: item4.trackID, targetTrackId: item4.trackID)
            
            transform1.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: item1.trackID)
//
            transform2.saveUniformSettings(forTimelineRange: item2.timeRange, trackID: item2.trackID)
//
            transform3.saveUniformSettings(forTimelineRange: item3.timeRange, trackID: item3.trackID)
//
            transform4.saveUniformSettings(forTimelineRange: item4.timeRange, trackID: item4.trackID)

            let layer1 = MetalVideoProcessBlendFilter()
            
            background --> layer1
            transform1 --> layer1
            
//            layer1.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: item1.trackID)

            let layer2 = MetalVideoProcessBlendFilter()
            
            layer1 --> layer2
            transform2 --> layer2
//
//            layer2.saveUniformSettings(forTimelineRange: item2.timeRange, trackID: item2.trackID)
//
            let layer3 = MetalVideoProcessBlendFilter()
            
            layer2 --> layer3
            transform3 --> layer3
//            layer3.saveUniformSettings(forTimelineRange: item3.timeRange, trackID: item3.trackID)
            
            let layer4 = MetalVideoProcessBlendFilter()
            
            layer3 --> layer4
            transform4 --> layer4
//            layer4.saveUniformSettings(forTimelineRange: item4.timeRange, trackID: item4.trackID)
//
            
            self.progress.minimumValue = 0.0
            self.progress.maximumValue = Float(playerItem.duration.seconds)
           

           
            layer4 --> renderView
//            layer3 --> self.renderView
//            transform1 --> self.renderView

            self.player = player
            self.player?.playerDelegate = self
            
        } catch {
            debugPrint("init error")
        }
    }
    
    @IBAction func play(_ sender: Any) {
        self.player?.play()
    }
    
    @IBAction func pause(_ sender: Any) {
        self.player?.pause()
    }
    
    @IBAction func progressChanged(_ sender: UISlider) {
        let value = sender.value
        
//        self.player?.seekTo(time: Float64(value))
    }
}

extension ViewController: MetalVideoProcessPlayerDelegate {
    func playbackFrameTimeChanged(frameTime time: CMTime, player: AVPlayer) {
        DispatchQueue.main.async {
            self.progress.value = Float(time.seconds)
            self.timeLabel.text = NSString(format: "%.2f", time.seconds) as String
        }
    }
    
    func playEnded(currentPlayer player: AVPlayer) {
        
    }
    
    func finishExport(error: NSError?) {
        
    }
    
    func exportProgressChanged(_ progress: Float) {
        
    }
}

