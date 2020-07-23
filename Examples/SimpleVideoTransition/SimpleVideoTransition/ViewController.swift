//
//  ViewController.swift
//  SimpleVideoTransition
//
//  Created by RenZhu Macro on 2020/7/2.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import MetalVideoProcess
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    @IBOutlet weak var progress: UISlider!
    var player: MetalVideoProcessPlayer?
    var beauty1: MetalVideoProcessBeautyFilter?
    var beauty2: MetalVideoProcessBeautyFilter?
    
    var blur1: MetalVideoProcessGaussianBlurFilter?
    var blur2: MetalVideoProcessGaussianBlurFilter?
    
    var grayFilter: MetalVideoProcessLuminance?
    
    public var transition: MetalVideoProcessTransition? = MetalVideoProcessFadeTransition()
    deinit {
    
        print(" ViewController deinit")
        
    }
    
    override func viewDidLoad() {
        guard let transition = self.transition else {
            return
        }
        super.viewDidLoad()
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "853", withExtension: "mp4")!)
        let asset2 = AVAsset(url: Bundle.main.url(forResource: "cute", withExtension: "mp4")!)
        let item1 = MetalVideoEditorItem(asset: asset1)
        let item2 = MetalVideoEditorItem(asset: asset2)
        
        //set transition before build editor
        let transitionDuration = CMTime.init(seconds: 2.0, preferredTimescale: 600)
        item1.videoTransition = TransitionDuration(duration: transitionDuration)
        item1.audioTransition = FadeInOutAudioTransition(duration: transitionDuration)
        
        
        do {
            let editor = try MetalVideoEditor(videoItems: [item1, item2],
                                              customVideoCompositorClass: MetalVideoProcessCompositor.self)
            
            let playerItem = editor.buildPlayerItem()
            self.progress.maximumValue = Float(playerItem.duration.seconds)
            let player = try MetalVideoProcessPlayer(playerItem: playerItem)
            let transitionTimeRange = item1.timeRange.intersection(item2.timeRange)
            
            
            //注意顺序 第一个视频在前 第二视频在后
            transition.mainTrackIDs.append(item1.trackID)
            transition.mainTrackIDs.append(item2.trackID)
            
            //告知转场的时间 通过item1和item2的intersection计算
            transition.saveUniformSettings(forTimelineRange: transitionTimeRange, trackID: 0)
            item1.transitoin = transition
            
            //Begin build pipeline
            player.addTarget(transition, atTargetIndex: nil, trackID: item1.trackID, targetTrackId: 0)
            player.addTarget(transition, atTargetIndex: nil, trackID: item2.trackID, targetTrackId: item2.trackID)
           
           transition --> renderView
           
            self.player = player
            self.player?.playerDelegate = self
            self.player?.play()
        } catch {
            debugPrint("init error")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
//        player?.suspend()
        player?.dispose()
//        player?.removeAllTargets()
//        player = nil
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


