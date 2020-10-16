//
//  ViewController.swift
//  SimpleVideoExport
//
//  Created by RenZhu Macro on 2020/7/6.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import AVFoundation
import MetalVideoProcess
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    @IBOutlet weak var progress: UISlider!
    private var progressHUD: MBProgressHUD?
    
    var player: MetalVideoProcessPlayer?
    var movieWriter: MetalVideoProcessMovieWriter?
    var videoBackground: MetalVideoProcessBackground = MetalVideoProcessBackground(trackID: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "cute", withExtension: "mp4")!)
        let asset2 = AVAsset(url: Bundle.main.url(forResource: "movie", withExtension: "mov")!)
        let item1 = MetalVideoEditorItem(asset: asset1)
        let item2 = MetalVideoEditorItem(asset: asset2)
        
        let transform1 = MetalVideoProcessTransformFilter()
        let transform2 = MetalVideoProcessTransformFilter()
        
        let backgroundFrame = self.renderView.frame
        let backgroundSize = CGSize(width: backgroundFrame.size.width * 2.0,
                                    height: backgroundFrame.size.height * 2.0)
        MetalVideoProcessBackground.canvasSize = backgroundSize
        transform1.stretchType = .aspectToFit
        transform1.roi = CGRect(x: 0.0, y: 0.0,
                                width: 1.0,
                                height: 1.0)
        
        transform2.stretchType = .aspectToFit
        transform2.roi = CGRect(x: 0.5, y: 0.0, width: 0.5, height: 0.5)
        
        videoBackground.canvasSizeType = .Type720p
        videoBackground.aspectRatioType = .Ratio3_4
        videoBackground.setBackgroundType(type: .Blur)
        
        do {
            let editor = try MetalVideoEditor(videoItems: [item1],
                                              overlayItems: [item2],
                                              customVideoCompositorClass: MetalVideoProcessCompositor.self)
            let playerItem = editor.buildPlayerItem()
            
            self.progress.maximumValue = Float(playerItem.duration.seconds)
            
            let beautyFilter = MetalVideoProcessBeautyFilter()
            
            beautyFilter.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: item1.trackID)
            
            let player = try MetalVideoProcessPlayer(playerItem: playerItem)
            
            player.addTarget(beautyFilter, trackID: item1.trackID, targetTrackId: item1.trackID)
            player.addTarget(videoBackground, trackID: item1.trackID, targetTrackId: item1.trackID) //blur background
            player.addTarget(transform2, trackID: item2.trackID, targetTrackId: item2.trackID)
            
            transform1.saveUniformSettings(forTimelineRange: item1.timeRange, trackID: item1.trackID)
            
            transform2.saveUniformSettings(forTimelineRange: item2.timeRange, trackID: item2.trackID)
            
            
            
            
            let layer1 = MetalVideoProcessBlendFilter()
            
            videoBackground --> layer1
            beautyFilter --> transform1 --> layer1
            
            let layer2 = MetalVideoProcessBlendFilter()
            
            layer1 --> layer2
            transform2 --> layer2
            
            layer2 --> renderView
            
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
    
    @IBAction func export(_ sender: Any) {
        
        self.progressHUD = MBProgressHUD.showHub(with: .loading("exporting"), self.view, isUserInteractionEnabled: false)
        
        
        guard let source = self.renderView?.sources.sources[0] else {
            return
        }
        initWriter()
        source.removeAllTargets()
        source --> self.movieWriter!
        self.view.isUserInteractionEnabled = false
        
        
        self.movieWriter?.activateAudioTrack()
        self.movieWriter?.startRecording()
        try? self.player?.startExport()
        
    }
    
    @objc func showInfo() {
        let data  = NSData(contentsOf: self.movieWriter!.fileURL)
        guard let size = data?.length else {
            return
        }
        
        let mSize = Double(size) / (1024 * 1024)
        let message = NSString(format: "%..2f MB", mSize) as String
        let alertVC = UIAlertController(title: "Video file size", message: message, preferredStyle: .alert)
        
        let alertBtn = UIAlertAction(title: "OK", style: .cancel) { (_) in
            alertVC.dismiss(animated: true, completion: nil)
        }
        alertVC.addAction(alertBtn)
        self.present(alertVC, animated: true) {
            
        }
    }
    
    fileprivate func initWriter() {
        self.movieWriter?.removeSourceAtIndex(0)
        self.movieWriter = nil
        //导出相关
        do {
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
            do {
                try FileManager.default.removeItem(at:fileURL)
            } catch {
            }
            

            let cgSize = MetalVideoProcessBackground.canvasSize
            self.movieWriter = try MetalVideoProcessMovieWriter(URL: fileURL,
                                                           size: Size(width: Float(cgSize.width),
                                                                      height: Float(cgSize.height)),
                                                           liveVideo: false)
            self.player?.audioEncodingTarget = nil
            self.player?.audioEncodingTarget = self.movieWriter
            //最后一个输出节点指向writer
            
            
            
        } catch {
            
        }
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
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if error != nil {
                MBProgressHUD.hide(for: self.view, animated: true)
                guard let source = self.movieWriter?.sources.sources[0] else {
                    return
                }
                source.removeAllTargets()
                source --> self.renderView
                self.view.isUserInteractionEnabled = true
                let alertVC = UIAlertController(title: "", message: "导出失败, 请重新尝试", preferredStyle: .alert)
                
                let alertBtn = UIAlertAction(title: "确认", style: .cancel) { (_) in
                    alertVC.dismiss(animated: true, completion: nil)
                }
                alertVC.addAction(alertBtn)
                self.present(alertVC, animated: true) {
                    
                }
                return
            }
        }
        if error != nil {
            self.view.isUserInteractionEnabled = true
            return
        }
        //这里准备调用writer结束
        self.movieWriter?.finishRecording({
            //这里去预览界面播放编辑后的视频
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                guard let source = self.movieWriter?.sources.sources[0] else {
                    return
                }
                source.removeAllTargets()
                source --> self.renderView
                
                let playerVC = AVPlayerViewController()
                playerVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .done, target: self, action: #selector(self.showInfo))
                playerVC.player = AVPlayer.init(url: self.movieWriter!.fileURL)
                self.present(playerVC, animated: true, completion: nil)
                self.view.isUserInteractionEnabled = true
            }
            
        })
    }
    
    func exportProgressChanged(_ progress: Float) {
        DispatchQueue.main.async {
            self.progressHUD?.progress = progress
        }
    }
    
    
}


