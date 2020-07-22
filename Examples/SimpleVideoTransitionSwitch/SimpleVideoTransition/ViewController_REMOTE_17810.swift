//
//  ViewController.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/2.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import MetalVideoProcess

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: MetalVideoProcessRenderView!
    @IBOutlet weak var mainEditButton: UIButton!
    @IBOutlet weak var mainDeleteButton: UIButton!
    
    @IBOutlet weak var subEditButton: UIButton!
    @IBOutlet weak var subDeleteButton: UIButton!
    
    var mainPicker: UIImagePickerController?
    var subPicker: UIImagePickerController?
    
    var mainLayer: MetalVideoProcessBlendFilter?
    var player: MetalVideoProcessPlayer?
    var movieWriter: MetalVideoProcessMovieWriter?
    var videoBackground: MetalVideoProcessBackground = MetalVideoProcessBackground(trackID: 0)
    var pop: PopupDialog?
    var progressHUD: MBProgressHUD?
    
    var mainResources: [ResourceItem] = []
    var lastMainLayerItem: ResourceItem?
    
    @IBOutlet weak var mainTableView: UITableView!
    var mainDragger: TableViewDragger?
    var videoEditor: MetalVideoEditor?
    var mainSelectedItem: ResourceItem?
    
    var subResources: [ResourceItem] = []
    @IBOutlet weak var subTableView: UITableView!
    var subDragger: TableViewDragger?
    var subSelectedItem: ResourceItem?
    
    @IBOutlet weak var progress: UISlider!
    
    private var rotGes: UIRotationGestureRecognizer?
    private var pinchGes: UIPinchGestureRecognizer?
    var currentPostion: Position = Position(0.0, 0.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        
        self.mainTableView.register(ResourceItemTableViewCell.self, forCellReuseIdentifier: "mainCell")
        self.mainTableView.allowsSelection = true
        self.mainTableView.dataSource = self
        self.mainTableView.delegate = self
        
        self.subTableView.register(ResourceItemTableViewCell.self, forCellReuseIdentifier: "pipCell")
        self.subTableView.allowsSelection = true
        self.subTableView.dataSource = self
        self.subTableView.delegate = self
        
        self.mainDragger = TableViewDragger(tableView: self.mainTableView)
        self.mainDragger?.delegate = self
        self.subDragger = TableViewDragger(tableView: self.subTableView)
        self.subDragger?.delegate = self
        
        let asset1 = AVAsset(url: Bundle.main.url(forResource: "cute", withExtension: "mp4")!)
        let asset2 = AVAsset(url: Bundle.main.url(forResource: "movie", withExtension: "mov")!)
        let sampleMainItem = ResourceItem(asset: asset1)
        let sampleSubItem = ResourceItem(asset: asset2)
        self.lastMainLayerItem = sampleMainItem

        
        let backgroundFrame = self.renderView.frame
        let backgroundSize = CGSize(width: backgroundFrame.size.width * 2.0,
                                    height: backgroundFrame.size.height * 2.0)
        MetalVideoProcessBackground.canvasSize = backgroundSize
        
        videoBackground.canvasSizeType = .Type720p
        videoBackground.aspectRatioType = .Ratio16_9
        videoBackground.setBackgroundType(type: .Blur)
        
        self.mainResources.append(sampleMainItem)
        self.subResources.append(sampleSubItem)
        
        
        
        self.progress.minimumValue = 0.0
        
        sampleMainItem.fillType = .aspectToFit
        sampleMainItem.roi = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        sampleSubItem.fillType = .aspectToFit
        sampleSubItem.roi = CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        self.rebuildPipeline()
        self.mainTableView.reloadData()
        self.subTableView.reloadData()
        
        self.renderView.isUserInteractionEnabled = true
        
        rotGes = UIRotationGestureRecognizer(target: self,
                                             action: #selector(self.rotateAction))
        rotGes!.delegate = self;
        pinchGes = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchAction))
        pinchGes!.delegate = self;
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(self.panAction))
        panGes.delegate = self
        self.renderView.addGestureRecognizer(rotGes!)
        self.renderView.addGestureRecognizer(pinchGes!)
        self.renderView.addGestureRecognizer(panGes)
    }
    
    @IBAction func changeFillType(_ sender: UIButton) {
        let tag = sender.tag
        switch tag {
        case 0:
            self.videoBackground.aspectRatioType = .Ratio16_9
            break
        case 1:
            self.videoBackground.aspectRatioType = .Ratio9_16
        case 2:
            self.videoBackground.aspectRatioType = .Ratio1_1
        case 3:
            self.videoBackground.aspectRatioType = .Ratio4_3
        case 4:
            self.videoBackground.aspectRatioType = .Ratio3_4
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
    
    
    @IBAction func importMain(_ sender: Any) {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.sourceType = .photoLibrary
        
        var pickerTypes: [String] = []
        
        pickerTypes.append(kUTTypeMovie as String)
        picker.mediaTypes = pickerTypes
        
        picker.allowsEditing = true
        self.navigationController?.present(picker, animated: true, completion: nil)
        self.mainPicker = picker
    }
    
    @IBAction func importPIP(_ sender: Any) {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.sourceType = .photoLibrary
        
        var pickerTypes: [String] = []
        
        pickerTypes.append(kUTTypeMovie as String)
        picker.mediaTypes = pickerTypes
        
        picker.allowsEditing = true
        self.navigationController?.present(picker, animated: true, completion: nil)
        self.subPicker = picker
    }
    
    @IBAction func progressChanged(_ sender: UISlider) {
        let value = sender.value
        self.player?.seekTo(time: Float64(value))
    }
    
    @IBAction func editItem(_ sender: UIButton) {
        
        let resourceEditView = ResourceItemEditView(nibName: "ResourceItemEditView", bundle: nil)
        self.pop = PopupDialog(viewController: resourceEditView, buttonAlignment: .horizontal, transitionStyle: .bounceDown, tapGestureDismissal: true, panGestureDismissal: false)
        
        let btnCancel = CancelButton(title: "Cancel", height: 60) {
            self.pop?.viewController.removeFromParent()
            self.pop?.removeFromParent()
            self.pop = nil
            return
        }
        
        let btnOK = DefaultButton(title: "OK", height: 60) {
            self.rebuildPipeline()
            self.mainTableView.reloadData()
            self.subTableView.reloadData()
            self.pop?.viewController.removeFromParent()
            self.pop?.removeFromParent()
            self.pop = nil
            return
        }
        
        pop?.addButtons([btnOK, btnCancel])
        if sender == self.mainEditButton {
            guard let item = self.mainSelectedItem else {
                return
            }
            self.present(pop!
            , animated: true) {
                resourceEditView.loadResourceItem(item)
            }
        } else {
            guard let item = self.subSelectedItem else {
                return
            }
            self.present(pop!
            , animated: true) {
                resourceEditView.loadResourceItem(item, isPipItem: true)
            }
        }
        
    }
    
    @IBAction func deleteItem(_ sender: UIButton) {
        
        if sender == self.mainDeleteButton {
            self.mainResources.removeAll { $0.trackID == self.mainSelectedItem?.trackID ?? 0 }
        } else {
            self.subResources.removeAll { $0.trackID == self.subSelectedItem?.trackID ?? 0 }
        }
        self.rebuildPipeline()
        self.mainTableView.reloadData()
        self.subTableView.reloadData()
        self.subEditButton.isEnabled = self.subResources.count > 0
        self.subDeleteButton.isEnabled = self.subResources.count > 0
        
        self.mainEditButton.isEnabled = self.mainResources.count > 0
        self.mainDeleteButton.isEnabled = self.mainResources.count > 0
    }
    
    func rebuildPipeline() {
        
        self.videoEditor = nil
        
        //rebuild player
        self.player?.suspend()
        self.player?.dispose()
        self.player?.removeAllTargets()
        self.player = nil
        
        //clear all sources
        renderView.sources.sources.removeAll()
        
        do {
            let currentEditor = try MetalVideoEditor(videoItems: self.mainResources, overlayItems: self.subResources)
            self.videoEditor = currentEditor
            try currentEditor.updateChannel()
            print("before build PlayerItem mainItems:", currentEditor.editorItems)
            print("before build PlayerItem overlayItems:", currentEditor.overlayItems)
            let playerItem = currentEditor.buildPlayerItem()
            print("after build PlayerItem mainItems:", currentEditor.editorItems)
            print("after build PlayerItem overlayItems:", currentEditor.overlayItems)
            
            
            
            self.progress.maximumValue = Float(playerItem.duration.seconds)
            let player = try MetalVideoProcessPlayer(playerItem: playerItem)
            
            let mainLayer = MetalVideoProcessBlendFilter()
            mainLayer.debugName = "mainLayer"
            var lastTransform: MetalVideoProcessTransformFilter? = nil
            for mainItem in self.mainResources {
                let transform = MetalVideoProcessTransformFilter()
                transform.saveUniformSettings(forTimelineRange: mainItem.timeRange, trackID: mainItem.trackID)
                transform.roi = mainItem.roi
                transform.debugName = "main transform trackId:\(mainItem.trackID)"
                //render blur background with every main track
                player.addTarget(videoBackground, atTargetIndex: nil, trackID: mainItem.trackID, targetTrackId: 0)
                
                mainItem.transformFilter = transform
                transform.rotate = mainItem.rotate
                transform.translation = mainItem.translation
                transform.scale = mainItem.scale
                
                
                mainItem.currentLayer = mainLayer
                if let lt = lastTransform {
                    //link every main transform in mainLayer
                    lt --> transform
                }
                lastTransform = transform
            }
            
            // make sure mapping every item‘s trackID on main track to main trackContainer with trackID 0,
            // if you don't do this, player can't render every item's texutre to item's target
            if let firstTransform = self.mainResources.first?.transformFilter {
                self.mainResources.forEach { (item) in
                    player.addTarget(firstTransform, atTargetIndex: nil, trackID: item.trackID, targetTrackId: 0)
                }
            }
            
            
            guard let lt = lastTransform else {
                // zero items
                self.player?.suspend()
                self.player?.dispose()
                self.player?.removeAllTargets()
                self.player = nil
                return
            }
            
            videoBackground --> mainLayer
            // place lt on videoBackground, secondary source to mainLayer
            lt --> mainLayer
            
            var lastLayer: MetalVideoProcessBlendFilter = mainLayer
            
            for subItem in self.subResources {
                let pipLayer = MetalVideoProcessBlendFilter()

                // render pipLayer in subItem.timeRange
                pipLayer.saveUniformSettings(forTimelineRange: subItem.timeRange, trackID: subItem.trackID)

                let transform = MetalVideoProcessTransformFilter()
                // transform subItem's texture in subItem.timeRange
                transform.saveUniformSettings(forTimelineRange: subItem.timeRange, trackID: subItem.trackID)
                transform.roi = subItem.roi

                // create a new targetContainer for subItem & pipLayer
                player.addTarget(transform, atTargetIndex: nil, trackID: subItem.trackID, targetTrackId: subItem.trackID)

                subItem.currentLayer = pipLayer
                subItem.transformFilter = transform
                transform.rotate = subItem.rotate
                transform.translation = subItem.translation
                transform.scale = subItem.scale
                //compositing two layer (warning!!! place transform to secondary source to pipLayer)
                lastLayer --> pipLayer
                transform --> pipLayer


                lastLayer = pipLayer
            }
            
            //render the final layer
            lastLayer --> renderView
            player.playerDelegate = self
            self.player = player
            
        } catch {
            
        }
    }
}

