//
//  MetalVideoEditor.swift
//  VideoEditor
//  
//  Created by RenZhu Macro on 2020/5/21.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import AVFoundation

public enum VideoError: Error {
    case videoFileNotFind
    case videoTrackNotFind
    case audioTrackNotFind
    case compositionTrackInitFailed
    case targetSizeNotCorrect
    case timeSetNotCorrect
}

public enum OMItemType {
    case image
    case video
    case imageFrames
}

open class MetalVideoEditorItem: TrackItem {
    
    public var itemType: OMItemType
    public var isMute: Bool
    
    public weak var transitoin: MetalVideoProcessTransition?
    
    public init(asset: AVAsset,
                contentMode: BaseContentMode = .aspectFit,
                itemType: OMItemType = .video,
                isMute: Bool = false) {
        self.isMute = isMute
        let resource = AVAssetTrackResource(asset: asset)
        self.itemType = itemType
        super.init(resource: resource)
        self.videoConfiguration.contentMode = contentMode
    }
    
    public init(asset: AVAsset,
                currentRange timeRange: CMTimeRange,
                contentMode: BaseContentMode = .aspectFill,
                itemType: OMItemType = .video,
                isMute: Bool = false) {
        self.isMute = isMute
        let resource = AVAssetTrackResource(asset: asset)
        self.itemType = itemType
        super.init(resource: resource)
        self.videoConfiguration.contentMode = contentMode
        self.startTime = timeRange.start
        self.duration = timeRange.duration
    }
    
    public required init(resource: Resource, trackID: Int32 = 0) {
        self.itemType = (resource.classForCoder == ImageResource.self) ? .image: .video
        self.isMute = false
        super.init(resource: resource, trackID: trackID)
    }
    
    public override var description: String {
        get {
            return "trackID: \(self.trackID), timeRange: {start: \(self.startTime.seconds), duration: \(self.duration.seconds)}>"
        }
    }

}

open class MetalVideoEditor: NSObject {
    
    public static var canvasSize: CGSize = CGSize(width: 1000, height: 1000)
    
    /// 时间轴 该时间轴的RenderSize 仅适用于 Timeline的缩略图，渲染交给外部渲染引擎
    public var timeline: Timeline = Timeline()
    
    /// 当前生成的PlayerItem
    public var playerItem: AVPlayerItem?
    
    /// 外部可以不通过内部提供的编辑方法进行手动更改，但最终虚拟时间轴资源需要通过Build方式生成
    public var editorItems: [MetalVideoEditorItem] = []
    
    /// 画中画对象 需要自行设定起始时间
    public var overlayItems: [MetalVideoEditorItem] = []
    
    public var customVideoCompositorClass: AVVideoCompositing.Type
    
    /// 根据一个或者多个videoItems生成editor
    /// - Parameter videoItems: 描述视频片段所在的位置
    ///   - rootItem: 根节点
    public init(videoItems: [MetalVideoEditorItem],
                overlayItems: [MetalVideoEditorItem] = [],
                customVideoCompositorClass: AVVideoCompositing.Type = MetalVideoProcessCompositor.self) throws {
        self.customVideoCompositorClass = customVideoCompositorClass
        super.init()
        self.editorItems = videoItems
        self.overlayItems = overlayItems
        try self.updateChannel()
        
    }
    
    
    /// 通过当前时间获取当前需要处理的视频片段的时间范围 用于特效处理
    /// - Parameter time: 当前时间
    /// - Returns: 当前需要处理的视频片段的范围
    public func timelineRange(withCurrentTime time: CMTime) -> CMTimeRange {
        if self.editorItems.count == 0 {
            return .zero
        }
        for item in self.editorItems {
            if(item.timeRange.containsTime(time)) || item.timeRange.end == time {
                return item.timeRange
            }
        }
        return .zero
    }
    
    
    /// 根据时间信息返回当前存在的视频片段，如果有画中画可能存在多个
    /// - Parameter time: 时间帧
    /// - Returns: 一个或者多个，由overlay和editor组成，主轴和分轴
    public func currentItems(withCurrentTime time: CMTime) -> [MetalVideoEditorItem]? {
        var result: [MetalVideoEditorItem]? = []
        
        for item in self.editorItems {
            if(item.timeRange.containsTime(time)) || item.timeRange.end == time {
                result?.append(item)
            }
        }
        
        for item in self.overlayItems {
            if(item.timeRange.containsTime(time)) || item.timeRange.end == time {
                result?.append(item)
            }
        }
        
        return result
    }
    
    /// 生成PlayerItem 一般用于回放，生成缩略图
    /// - Returns: PlayerItem
    public func buildPlayerItem() -> AVPlayerItem {
        let compositionGenerator = CompositionGenerator(timeline: self.timeline)
        let playerItem = compositionGenerator.buildPlayerItem(customVideoCompositorClass: self.customVideoCompositorClass)
        self.playerItem = playerItem
        return playerItem
    }
    
    public func buildImageGenerator() -> AVAssetImageGenerator {
        let compositionGenerator = CompositionGenerator(timeline: self.timeline)
        let imageGenerator = compositionGenerator.buildImageGenerator()
        return imageGenerator
    }
    
    // MARK: - Edit Operations
    /// 在时间轴最后插入某个片段
    /// - Parameter videoItem: 片段信息
    public func insertItem(videoItem: MetalVideoEditorItem) throws {
        self.editorItems.append(videoItem)
        try self.updateChannel()
    }
    
    public func insertOverlayItem(overlayItem: MetalVideoEditorItem) throws {
        self.overlayItems.append(overlayItem)
        try self.updateChannel()
    }
    
    /// 删除某个片段
    /// - Parameter videoItem: 片段信息
    public func removeItem(videoItem: MetalVideoEditorItem) throws {
        guard let index = self.editorItems.firstIndex(of: videoItem) else {
            throw VideoError.videoTrackNotFind
        }
        self.editorItems.remove(at: index)
        try self.updateChannel()
    }
    
    
    /// 在某个节点分割一个视频片段产生2个视频item并重新build整个虚拟资源 并更新到editorItems里
    /// - Parameters: 
    ///   - videoItem: 需要分割的视频item
    ///   - splitTime: 虚拟资源上中间时间点 需要根据该值计算mainTimeline上的节点
    public func split(videoItem: MetalVideoEditorItem,
                      splitTime: CMTime) throws {
        let newItem = MetalVideoEditorItem(resource: videoItem.resource)
        let endTime = videoItem.timeRange.end
        let newStart = splitTime
        
        newItem.startTime = newStart
        newItem.duration = endTime - newStart
        
        guard let index = self.editorItems.firstIndex(of: videoItem) else {
            throw VideoError.videoTrackNotFind
        }
        
        videoItem.duration = videoItem.duration - newItem.duration //原有视频缩短
        self.editorItems.insert(newItem, at: index)
        //结束 外部需要根据情况 手动buildPlayerItem
        try self.updateChannel()
    }
    
    
    /// 裁剪某个片段
    /// - Parameters: 
    ///   - videoItem: 片段item
    ///   - duration: 裁剪后的新时长
    public func cut(videoItem: MetalVideoEditorItem, range: CMTimeRange) throws {
        videoItem.startTime = range.start
        videoItem.duration = range.duration
        try self.updateChannel()
    }
    
    public func updateChannel() throws {
        self.timeline.videoChannel = self.editorItems
        self.timeline.audioChannel = self.editorItems.filter { !$0.isMute }
        self.timeline.overlays = self.overlayItems
        self.timeline.audios = self.overlayItems.filter { !$0.isMute }
        
//        try Timeline.reloadAudioStartTime(providers: timeline.audioChannel)
        try Timeline.reloadVideoStartTime(providers: timeline.videoChannel)
    }
     
}
