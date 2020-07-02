//
//  ViewController.swift
//  SimpleRealtimeFilterPlayback
//
//  Created by RenZhu Macro on 2020/7/2.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import AVFoundation
import MetalVideoProcess

class ViewController: UIViewController {

    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    @IBOutlet weak var progress: UISlider!
    var player: MetalVideoProcessPlayer?
    var beauty1: MetalVideoProcessBeautyFilter?
    var beauty2: MetalVideoProcessBeautyFilter?
    
    var blur1: MetalVideoProcessGaussianBlurFilter?
    var blur2: MetalVideoProcessGaussianBlurFilter?
    
    var grayFilter: MetalVideoProcessLuminance?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "853", withExtension: "mp4")!)
        let asset2 = AVAsset(url: Bundle.main.url(forResource: "cute", withExtension: "mp4")!)
        let item1 = MetalVideoEditorItem(asset: asset1)
        let item2 = MetalVideoEditorItem(asset: asset2)
        
        do {
            let editor = try MetalVideoEditor(videoItems: [item1, item2],
                                              customVideoCompositorClass: MetalVideoProcessCompositor.self)

            let playerItem = editor.buildPlayerItem()
            self.progress.maximumValue = Float(playerItem.duration.seconds)
            let player = try MetalVideoProcessPlayer(playerItem: playerItem)
            
            let beautyFilter1 = MetalVideoProcessBeautyFilter()
            beautyFilter1.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: 0)
            beautyFilter1.isEnable = false
            
            let beautyFilter2 = MetalVideoProcessBeautyFilter()
            beautyFilter2.saveUniformSettings(forTimelineRange: item2.timeRange, trackID: 0)
            beautyFilter2.isEnable = false
            
            let blurFilter1 = MetalVideoProcessGaussianBlurFilter()
            blurFilter1.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: 0)
            blurFilter1.isEnable = false
            
            let blurFilter2 = MetalVideoProcessGaussianBlurFilter()
            blurFilter2.saveUniformSettings(forTimelineRange: item2.timeRange, trackID: 0)
            blurFilter2.isEnable = false
            
            player.addTarget(beautyFilter1, atTargetIndex: nil, trackID: item1.trackID, targetTrackId: 0)
            player.addTarget(beautyFilter1, atTargetIndex: nil, trackID: item2.trackID, targetTrackId: 0)
            //mapping trackId on mainTrack 0
            
            let gray = MetalVideoProcessLuminance()
            gray.isEnable = false
            self.grayFilter = gray
            
            self.beauty1 = beautyFilter1
            self.beauty2 = beautyFilter2
            
            self.blur1 = blurFilter1
            self.blur2 = blurFilter2
            
            beautyFilter1 --> beautyFilter2 --> blurFilter1 --> blurFilter2 --> gray --> renderView
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
        self.player?.seekTo(time: Float64(value))
    }
    
    @IBAction func filterOn(_ sender: UISwitch) {
        var operation: MetalVideoProcessOperation?
        switch sender.tag {
        case 0:
            operation = self.beauty1
            break
        case 1:
            operation = self.blur1
            
            break
        case 2:
            operation = self.beauty2
            break
        case 3:
            operation = self.blur2
            break
        case 4:
            operation = self.grayFilter
            break
        default:
            break
        }
        operation?.isEnable = sender.isOn
    }
}

extension ViewController: MetalVideoProcessPlayerDelegate {
    func playbackFrameTimeChanged(frameTime time: CMTime, player: AVPlayer) {
        DispatchQueue.main.async {
            self.progress.value = Float(time.seconds)
        }
    }
    
    func playEnded(currentPlayer player: AVPlayer) {
        
    }
    
    func finishExport(error: NSError?) {
        
    }
    
    func exportProgressChanged(_ progress: Float) {
        
    }
    
    
}

