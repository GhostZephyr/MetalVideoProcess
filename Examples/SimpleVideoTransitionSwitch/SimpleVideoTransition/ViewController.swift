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
    
    var transition: MetalVideoProcessTransition? {
        didSet {
            if let targets = oldValue?.targets {
               
                // 因为双向链，需要去除target的sourse, 需调用removeSourceAtIndex， 不建议用removeAll函数
                for target in targets {
                    for (index, _) in target.0.sources.sources.enumerated() {
                        target.0.removeSourceAtIndex(UInt(index))
                    }
                }
                
                for target in targets {
                    transition!.addTarget(target.0, trackID: 0)
                }
            }
            
            if let sourses = oldValue?.sources {
                
                for sourse in sourses.sources {
                    sourse.value --> transition!
                }
                
                for (i, _) in sourses.sources.enumerated() {
                    oldValue?.removeSourceAtIndex(UInt(i))
                }
            }
        }
    }
    
    var item1: MetalVideoEditorItem?
    var item2: MetalVideoEditorItem?
    var transitionTimeRange = CMTimeRange.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "853", withExtension: "mp4")!)
        let asset2 = AVAsset(url: Bundle.main.url(forResource: "cute", withExtension: "mp4")!)
        self.item1 = MetalVideoEditorItem(asset: asset1)
        self.item2 = MetalVideoEditorItem(asset: asset2)
        
        guard let item1 = self.item1, let item2 = self.item2 else {
            return
        }
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
            
            let beautyFilter1 = MetalVideoProcessBeautyFilter()
            beautyFilter1.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: item1.trackID)
            beautyFilter1.isEnable = false
            
            let beautyFilter2 = MetalVideoProcessBeautyFilter()
            beautyFilter2.saveUniformSettings(forTimelineRange: item2.timeRange, trackID: item2.trackID)
            beautyFilter2.isEnable = false
            
            let blurFilter1 = MetalVideoProcessGaussianBlurFilter()
            blurFilter1.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: item1.trackID)
            blurFilter1.isEnable = false
            
            let blurFilter2 = MetalVideoProcessGaussianBlurFilter()
            blurFilter2.saveUniformSettings(forTimelineRange: item2.timeRange, trackID: item2.trackID)
            blurFilter2.isEnable = false
            
            let gray = MetalVideoProcessLuminance()
            gray.isEnable = false
            self.grayFilter = gray
            
            self.beauty1 = beautyFilter1
            self.beauty2 = beautyFilter2
            
            self.blur1 = blurFilter1
            self.blur2 = blurFilter2
            
            self.transitionTimeRange = item1.timeRange.intersection(item2.timeRange)
            self.transition = MetalVideoProcessFadeTransition()
            guard let transition = self.transition else {
                return
            }
            
            //注意顺序 第一个视频在前 第二视频在后
            transition.mainTrackIDs.append(item1.trackID)
            transition.mainTrackIDs.append(item2.trackID)
            
            //告知转场的时间 通过item1和item2的intersection计算
            transition.saveUniformSettings(forTimelineRange: transitionTimeRange, trackID: 0)
            item1.transitoin = transition
            
            //Begin build pipeline
            player.addTarget(beautyFilter1, atTargetIndex: nil, trackID: item1.trackID, targetTrackId: 0)
            player.addTarget(beautyFilter2, atTargetIndex: nil, trackID: item2.trackID, targetTrackId: item2.trackID)
            //mapping trackId on mainTrack 0
            
            beautyFilter1 --> blurFilter1 --> transition
            beautyFilter2 --> blurFilter2 --> transition --> gray --> renderView
            //Done
                     
            self.player = player
            self.player?.playerDelegate = self
            
        } catch {
            debugPrint("init error")
        }
        
        let segment = UISegmentedControl(frame:CGRect(x: self.view.bounds.width * 0.1, y: 50, width: self.view.bounds.width * 0.8, height: 40))

        self.view.addSubview(segment)
        
        segment.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        segment.insertSegment(withTitle: "叠化", at: 0, animated: true)
        segment.insertSegment(withTitle: "闪白", at: 1, animated: true)
        segment.insertSegment(withTitle: "向下擦除", at: 2, animated: true)
        segment.insertSegment(withTitle: "镜像翻转", at: 3, animated: true)
        segment.insertSegment(withTitle: "倒影", at: 4, animated: true)
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(self.segmentValueChange(_:)), for: UIControl.Event.valueChanged)
    }

    
    private func resetTransInTrack() {
        guard let transition = self.transition, let item1 = self.item1, let item2 = self.item2 else {
            return
        }
        
        //注意顺序 第一个视频在前 第二视频在后
        transition.mainTrackIDs.append(item1.trackID)
        transition.mainTrackIDs.append(item2.trackID)
        
        //告知转场的时间 通过item1和item2的intersection计算
        transition.saveUniformSettings(forTimelineRange: transitionTimeRange, trackID:0)
        item1.transitoin = transition
    }
    
    @IBAction func segmentValueChange(_ sender: UISegmentedControl) {
        guard let transition = self.transition else {
            return
        }
        switch sender.selectedSegmentIndex {
        case 0:
            self.transition = MetalVideoProcessFadeTransition()
            resetTransInTrack()
            
            break
        case 1:
           
            self.transition = MetalVideoProcessShanBai()
            resetTransInTrack()
            break
        case 2:
            
            self.transition = MetalVideoProcessEraseDownTransition()
            resetTransInTrack()
            break
        case 3:
            
            self.transition = MetalVideoProcessMirrorRotateTransition()
            resetTransInTrack()
        case 4:
            
            self.transition = MetalVideoProcessReflectTransition()
            resetTransInTrack()
            break
        default:
            break
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


