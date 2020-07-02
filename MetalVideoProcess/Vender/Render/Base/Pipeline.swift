//
//  Pipeline.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/4/23.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import Metal

public protocol ImageSource {
    var targets: TargetContainer { get }
    var trackID: Int32 { get set }
    func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt, trackID: Int32)
}

public protocol ImageConsumer: AnyObject {
    var maximumInputs: UInt { get }
    var sources: SourceContainer { get }
    var isEnable: Bool { get }
    func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32)
}

public protocol ImageProcessingOperation: ImageConsumer, ImageSource {
    var debugName: String { get set }
}

infix operator -->: AdditionPrecedence

@discardableResult public func --><T: ImageConsumer>(source: ImageSource, destination: T) -> T {
    source.addTarget(destination, trackID: source.trackID)
    return destination
}


class WeakImageConsumer {
    weak var value: ImageConsumer?
    let indexAtTarget: UInt
    init (value: ImageConsumer, indexAtTarget: UInt) {
        self.indexAtTarget = indexAtTarget
        self.value = value
    }
}

public extension ImageSource {
    func addTarget(_ target: ImageConsumer, atTargetIndex: UInt? = nil, trackID: Int32) {
        if let targetIndex = atTargetIndex {
            target.setSource(self, atIndex: targetIndex)
            targets.append(target, indexAtTarget: targetIndex)
            transmitPreviousImage(to: target, atIndex: targetIndex, trackID: trackID)
        } else if let indexAtTarget = target.addSource(self) {
            targets.append(target, indexAtTarget: indexAtTarget)
            transmitPreviousImage(to: target, atIndex: indexAtTarget, trackID: trackID)
        } else {
            debugPrint("超过了maximumInputs：", target.maximumInputs)
        }
    }
    
    func removeAllTargets() {
        for (target, index) in targets {
            target.removeSourceAtIndex(index)
        }
        targets.removeAll()
    }
    
    func updateTargetsWithTexture(_ texture: Texture, trackID: Int32) {
        searchVisialbeTargets(targets: targets, texture: texture, trackID: trackID)
    }
    
    func searchVisialbeTargets(targets: TargetContainer, texture: Texture, trackID: Int32) {
        if targets.count == 0 {
            return
        }
        for (target, index) in targets {
            if (target.isEnable == true) {
                target.newTextureAvailable(texture, fromSourceIndex: index, trackID: trackID)
            } else {
                searchVisialbeTargets(targets: (target as? ImageProcessingOperation)!.targets, texture: texture, trackID: trackID)
            }
        }
    }
}

public extension ImageConsumer {
    func addSource(_ source: ImageSource) -> UInt? {
        return sources.append(source, maximumInputs: maximumInputs)
    }
    
    func setSource(_ source: ImageSource, atIndex: UInt) {
        _ = sources.insert(source, atIndex: atIndex, maximumInputs: maximumInputs)
    }
    
    func removeSourceAtIndex(_ index: UInt) {
        sources.removeAtIndex(index)
    }
}

public class TargetContainer: Sequence {
    var targets = [WeakImageConsumer]()
    var count: Int { get {return targets.count}}
    let dispatchQueue = DispatchQueue(label: "com.wangrenzhu.metalRender.targetContainerQueue", attributes: [])
    
    public init() {
    }
    
    public func append(_ target: ImageConsumer, indexAtTarget: UInt) {
        dispatchQueue.async {
            self.targets.append(WeakImageConsumer(value: target, indexAtTarget: indexAtTarget))
        }
    }
    
    public func makeIterator() -> AnyIterator<(ImageConsumer, UInt)> {
        var index = 0
        
        return AnyIterator { () -> (ImageConsumer, UInt)? in
            return self.dispatchQueue.sync{
                if (index >= self.targets.count) {
                    return nil
                }
                
                while (self.targets[index].value == nil) {
                    self.targets.remove(at: index)
                    if (index >= self.targets.count) {
                        return nil
                    }
                }
                
                index += 1
                return (self.targets[index - 1].value!, self.targets[index - 1].indexAtTarget)
            }
        }
    }
    
    public func removeAll() {
        dispatchQueue.async{
            self.targets.removeAll()
        }
    }
    
    public var debugDescription: String {
        var str = "->targets:\(self)\n"
        for target in self.targets {
            if let operation = target.value as? ImageProcessingOperation {
                
                str.append("operation:\(operation.debugName) \n     subTargets:\(operation.targets.debugDescription)")
            }
        }
        let rs = self.targets.filter { (weak) -> Bool in
            if let _ = weak.value as? ImageProcessingOperation {
                return true
            } else {
                return false
            }
        }.count
        if rs == 0 {
            str.append("-->Final\n")
        }
        
        return str
    }
}

public class SourceContainer {
    public var sources: [UInt: ImageSource] = [: ]
    
    public init() {
    }
    
    public func append(_ source: ImageSource, maximumInputs: UInt) -> UInt? {
        var currentIndex: UInt = 0
        while currentIndex < maximumInputs {
            if (sources[currentIndex] == nil) {
                sources[currentIndex] = source
                return currentIndex
            }
            currentIndex += 1
        }
        
        return nil
    }
    
    public func insert(_ source: ImageSource, atIndex: UInt, maximumInputs: UInt) -> UInt {
        guard (atIndex < maximumInputs) else {
            fatalError("超过允许的最大输入")
        }
        sources[atIndex] = source
        return atIndex
    }
    
    public func removeAtIndex(_ index: UInt) {
        sources[index] = nil
    }
}

public class ImageRelay: ImageProcessingOperation {
    public var debugName: String = ""
    
    public var trackID: Int32 = 0
    
    public var isEnable: Bool = true
    
    public var newImageCallback: ((Texture) -> ())?
    
    public let sources = SourceContainer()
    public let targets = TargetContainer()
    public let maximumInputs: UInt = 1
    public var preventRelay: Bool = false
    
    public init() {
    }
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt, trackID: Int32) {
        sources.sources[0]?.transmitPreviousImage(to: self, atIndex: 0, trackID: trackID)
    }
    
    public func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        if let newImageCallback = newImageCallback {
            newImageCallback(texture)
        }
        if (!preventRelay) {
            relayTextureOnward(texture, trackID: trackID)
        }
    }
    
    
    public func relayTextureOnward(_ texture: Texture, trackID: Int32) {
        for (target, index) in targets {
            target.newTextureAvailable(texture, fromSourceIndex: index, trackID: trackID)
        }
    }
    /*
    public func relayTextureOnwardWithSize(_ texture: Texture, size: CGSize) {
           for (target, index) in targets {
            target.newTextureAvailable(texture, fromSourceIndex: index, renderSize: size)
           }
    }
 */
}
