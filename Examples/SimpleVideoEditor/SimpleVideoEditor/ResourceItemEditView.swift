//
//  ResourceEditorViewController.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/8.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import MetalVideoProcess
import AVFoundation

class ResourceItemEditView: UIViewController {

    deinit {
        
    }
    
    public weak var resourceItem: ResourceItem?
    
    @IBOutlet weak var timeRangeText: UILabel!
    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    
    @IBOutlet weak var startTimeSlider: UISlider!
    
    @IBOutlet weak var durationSlider: UISlider!
    
    @IBOutlet weak var positionSlider: UISlider!
    
    var player: MetalVideoProcessPlayer?
    var editor: MetalVideoEditor?
    var assetDuration: CMTime = .zero
    
    @IBOutlet weak var isMuteSwitch: UISwitch!
    var isPipItem: Bool = false
    var isImageResource: Bool = false
    
    public func loadResourceItem(_ item: ResourceItem, isPipItem: Bool = false) {
        self.isPipItem = isPipItem
        self.resourceItem = item
        self.isMuteSwitch.isOn = item.isMute
        
        if let imageResource = item.resource as? ImageResource {
            self.isImageResource = true
            //picture
            let mtlTexture = imageResource.sourceTexture(at: .zero)!
            let texture = Texture(orientation: .landscapeLeft, texture: mtlTexture, timingStyle: .stillImage)
            self.renderView.newTextureAvailable(texture, fromSourceIndex: 0, trackID: 0)
            
            
        } else if let asset = (item.resource as? AVAssetTrackResource)?.asset {
            assetDuration = asset.duration
            self.editor = try? MetalVideoEditor(videoItems: [item])
            
            
            guard let playerItem = self.editor?.buildPlayerItem() else {
                return
            }
            
            self.player = try? MetalVideoProcessPlayer(playerItem: playerItem)
            
            let orientation = orientationForTrack(asset: asset)
            
            let transform = MetalVideoProcessTransformFilter()
            
            switch orientation {
            case .portrait:
                break
            case .landscapeLeft:
                transform.rotate = 90.0
                break
            case .landscapeRight:
                transform.rotate = -90.0
                break
            case .portraitUpsideDown:
                transform.rotate = 180.0
                break
            default:
                break
                
            }
            
            self.player?.addTarget(transform, atTargetIndex: nil, trackID: item.trackID, targetTrackId: 0)
            transform --> self.renderView
        } else {
            return //unsupported
        }
        
        
        
        self.startTimeSlider.minimumValue = 0.0
        
        //min value of a item is 0.1 seconds
        self.durationSlider.minimumValue = 0.1
        if self.isImageResource {
            self.durationSlider.maximumValue = 100.0
            assetDuration = CMTime(seconds: 100.0)
        } else {
            self.durationSlider.maximumValue = Float(assetDuration.seconds)
        }
        
        self.startTimeSlider.maximumValue = self.durationSlider.maximumValue - 0.1
        
        self.startTimeSlider.value = Float(item.resource.selectedTimeRange.start.seconds)
        self.durationSlider.value = Float(item.resource.selectedTimeRange.duration.seconds)
        self.positionSlider.value = Float(item.startTime.seconds)
        
        if self.isPipItem {
            self.positionSlider.isEnabled = true
            self.positionSlider.maximumValue = 100.0
            self.positionSlider.value = Float(item.startTime.seconds)
        }
        
        timeRangeText.text = NSString(format: "s:%.2f d:%.2f p:%.2f",
                                      self.startTimeSlider.value,
                                      self.durationSlider.value,
                                      self.positionSlider.value) as String
        
        self.player?.seekTo(time: 0.0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.player?.suspend()
        self.player?.dispose()
        self.player = nil
        self.editor = nil
    }
    
    @IBAction func positionValueChanged(_ sender: Any) {
        self.resourceItem?.startTime = CMTime(seconds: self.positionSlider.value)
        
        
        timeRangeText.text = NSString(format: "s:%.2f d:%.2f p:%.2f",
        self.startTimeSlider.value,
        self.durationSlider.value,
        self.positionSlider.value) as String
    }
    
    @IBAction func startTimeValueChanged(_ sender: Any) {
        let totalValue = self.startTimeSlider.value + self.durationSlider.value
        if totalValue > Float(self.assetDuration.seconds) {
            self.durationSlider.value = Float(self.assetDuration.seconds) - self.startTimeSlider.value
        }
        
        resourceItem?.resource.selectedTimeRange = CMTimeRange(start: CMTime(seconds: self.startTimeSlider.value),
                                                                    duration: CMTime(seconds: self.durationSlider.value))
        if self.isPipItem {
            self.player?.seekTo(time: Float64(resourceItem?.resource.selectedTimeRange.start.seconds ?? 0.0))
        } else {
            self.player?.seekTo(time: Float64(self.startTimeSlider.value))
        }
        timeRangeText.text = NSString(format: "s:%.2f d:%.2f p:%.2f",
        self.startTimeSlider.value,
        self.durationSlider.value,
        self.positionSlider.value) as String
        
    }
    
    @IBAction func DurationValueChanged(_ sender: Any) {
        let totalValue = self.startTimeSlider.value + self.durationSlider.value
        if totalValue > Float(self.assetDuration.seconds) {
            self.startTimeSlider.value = Float(self.assetDuration.seconds) - self.durationSlider.value
        }
        resourceItem?.resource.selectedTimeRange = CMTimeRange(start: CMTime(seconds: self.startTimeSlider.value),
                                                            duration: CMTime(seconds: self.durationSlider.value))
        timeRangeText.text = NSString(format: "s:%.2f d:%.2f p:%.2f",
        self.startTimeSlider.value,
        self.durationSlider.value,
        self.positionSlider.value) as String
        if self.isImageResource {
            //No need to render the image with frameTime
            return
        }
        self.player?.seekTo(time: Float64(self.startTimeSlider.value + self.durationSlider.value))
    }
    
    
    @IBAction func isMuteOn(_ sender: UISwitch) {
        self.resourceItem?.isMute = sender.isOn
    }
    
    @IBAction func play(_ sender: Any) {
        guard let playerItem = self.editor?.buildPlayerItem() else {
            return
        }
        self.player?.updatePlayerItem(playerItem: playerItem)
        
        self.player?.play()
    }
    
    @IBAction func pause(_ sender: Any) {
        self.player?.pause()
    }
}
