//
//  ViewController+MetalVideoProcessPlayerDelegate.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/9.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import MetalVideoProcess
import AVFoundation
import AVKit

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
    
    func initWriter() {
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
    
    @IBAction func export(_ sender: Any) {
           self.progressHUD = MBProgressHUD.showHub(with: .loading("exporting..."), self.view, isUserInteractionEnabled: false)
           
           
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
}
