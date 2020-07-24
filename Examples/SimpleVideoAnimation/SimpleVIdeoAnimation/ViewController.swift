//
//  ViewController.swift
//  SimpleVideoAnimation
//
//  Created by RenZhu Macro on 2020/7/20.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import AVFoundation
import MetalVideoProcess
import PryntTrimmerView


class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    
    @IBOutlet weak var progressView: TrimmerView!
    
    var player: MetalVideoProcessPlayer?
    var editor: MetalVideoEditor?
    public var motionIn: MetalVideoProcessMotion = MetalVideoProcessMoveInMotion()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "853", withExtension: "mp4")!)
        
        let item1 = MetalVideoEditorItem(asset: asset1)
        
        do {
            let editor = try MetalVideoEditor(videoItems: [item1])
            self.editor = editor
            let playerItem = editor.buildPlayerItem()
            
            let fadeIn = motionIn
            fadeIn.timingType = .quadraticEaseOut
            
            let fadeOut = MetalVideoProcessFadeOutMotion()
            fadeOut.timingType = .quarticEaseOut
 
            let fadeInTimeRange = CMTimeRangeMake(start: CMTime(seconds: 0.0), duration: CMTime(seconds: 2.0))
            fadeIn.saveUniformSettings(forTimelineRange: fadeInTimeRange, trackID: item1.trackID)
            
            let fadeOutTimeRange = CMTimeRange(start: item1.timeRange.end - CMTime(seconds: 4.0), duration: CMTime(seconds: 1.5))
            fadeOut.saveUniformSettings(forTimelineRange: fadeOutTimeRange, trackID: item1.trackID)
 
            let player = try MetalVideoProcessPlayer(playerItem: playerItem)
            player.playerDelegate = self
            
            let background = MetalVideoProcessBackground(trackID: 0)
            background.aspectRatioType = .Ratio9_16
            background.canvasSizeType = .Type720p
            background.setBackgroundType(type: .Blur)
            
            let transform = MetalVideoProcessTransformFilter()
                       transform.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: item1.trackID)
            transform.roi = CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            fadeIn.roi = transform.roi
            player.addTarget(background, atTargetIndex: 0, trackID: item1.trackID, targetTrackId: 0)
             
            background --> fadeIn //source 0
            player.addTarget(transform, atTargetIndex: nil, trackID: item1.trackID, targetTrackId: 0) //source 1
            
            transform --> fadeIn --> renderView //source 1

            self.player = player
        } catch {
            
        }
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        guard let asset = self.editor?.playerItem?.asset else {
            return
        }
        self.progressView.asset = asset
        self.progressView.delegate = self
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
    
    @IBAction func progressChanged(_ sender: Any) {
    }
}

extension ViewController: TrimmerViewDelegate {
    func didChangePositionBar(_ playerTime: CMTime) {
        self.player?.seekTo(time: playerTime.seconds)
    }
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        
    }
}

extension ViewController: MetalVideoProcessPlayerDelegate {
    func playbackFrameTimeChanged(frameTime time: CMTime, player: AVPlayer) {
        if player.rate == 0.0 {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.progressView.seek(to: time)
        }
        
    }
    
    func playEnded(currentPlayer player: AVPlayer) {
        
    }
    
    func finishExport(error: NSError?) {
        
    }
    
    func exportProgressChanged(_ progress: Float) {
        
    }
}
