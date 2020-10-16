//
//  PlaygroundVC.swift
//  SimpleRealtimeFilterPlayback
//
//  Created by wangrenzhu on 2020/9/30.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import AVFoundation
import MetalVideoProcess


class PlaygroundVC: UIViewController {

    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    @IBOutlet weak var progress: UISlider!
    
    var grayFilter: MetalVideoProcessLuminance?
    var player: MetalVideoProcessPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "853", withExtension: "mp4")!)
        let item1 = MetalVideoEditorItem(asset: asset1)
        
        do {
            let editor = try MetalVideoEditor(videoItems: [item1],
                                              customVideoCompositorClass: MetalVideoProcessCompositor.self)
            
            let playerItem = editor.buildPlayerItem()
            self.progress.maximumValue = Float(playerItem.duration.seconds)
            let player = try MetalVideoProcessPlayer(playerItem: playerItem)
            
            let gray = MetalVideoProcessLuminance()
            gray.saveUniformSettings(forTimelineRange: CMTimeRange(start: CMTime(seconds: 0.5), duration: CMTime(seconds: 3.0)), trackID: item1.trackID)
            gray.isEnable = true
            self.grayFilter = gray
            
            player.addTarget(gray, atTargetIndex: nil, trackID: item1.trackID, targetTrackId: 0)
            gray --> renderView
            
            player.playerDelegate = self
            self.player = player
        } catch {
            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.player?.suspend()
        self.player?.dispose()
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

}

extension PlaygroundVC: MetalVideoProcessPlayerDelegate {
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
