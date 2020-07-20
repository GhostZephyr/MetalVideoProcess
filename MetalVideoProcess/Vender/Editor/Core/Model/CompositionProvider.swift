//
//  CompositionProvider.swift
//  Cabbage
//
//  Created by Vito on 2018/6/23.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreImage
import AVFoundation

public protocol CompositionTimeRangeProvider: class {
    var startTime: CMTime { get set }
    var duration: CMTime { get }
}

public extension CompositionTimeRangeProvider {
    var timeRange: CMTimeRange {
        get {
            return CMTimeRange.init(start: startTime, duration: duration)
        }
    }
}

public protocol VideoCompositionTrackProvider: class {
    func numberOfVideoTracks() -> Int
    func videoCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack?
}

public protocol AudioCompositionTrackProvider: class {
    func numberOfAudioTracks() -> Int
    func audioCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack?
}

public protocol AudioMixProvider {
    func configure(audioMixParameters: AVMutableAudioMixInputParameters)
}

public protocol VideoCompositionProvider: class {
    
    /// Apply effect to sourceImage
    ///
    /// - Parameters: 
    ///   - sourceImage: sourceImage is the original image from resource
    ///   - time: time in timeline
    ///   - renderSize: the video canvas size
    /// - Returns: result image after apply effect
    func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage
    
}

public protocol VideoProvider: CompositionTimeRangeProvider, VideoCompositionTrackProvider, VideoCompositionProvider {
    //这个标识符用于区分原始来源的纹理
    var trackID: Int32 { get set}
}
public protocol AudioProvider: CompositionTimeRangeProvider, AudioCompositionTrackProvider, AudioMixProvider { }

public protocol TransitionableVideoProvider: VideoProvider {
    var videoTransition: VideoTransition? { get }
}

public protocol TransitionableAudioProvider: AudioProvider {
    var audioTransition: AudioTransition? { get }
}
