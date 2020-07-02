public class ImageGenerator: ImageSource {
    public var trackID: Int32
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt, trackID: Int32) {
        target.newTextureAvailable(internalTexture,
                                   fromSourceIndex: atIndex,
                                   trackID: trackID)
    }
    
    public var size: Size

    public let targets = TargetContainer()
    var internalTexture: Texture!

    public init(size: Size,
                trackID: Int32) {
        self.size = size
        internalTexture = Texture(device: sharedMetalRenderingDevice.device, orientation: .portrait, width: Int(size.width), height: Int(size.height), timingStyle: .stillImage)
        self.trackID = trackID
    }
    
    func notifyTargets() {
        updateTargetsWithTexture(internalTexture, trackID: self.trackID)
    }
}
