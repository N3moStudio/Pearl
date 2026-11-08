import AppKit
import AVFoundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fixtures = root.appending(path: "build/fixtures")
try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
let icons = root.appending(path: "App/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: icons, withIntermediateDirectories: true)

func drawImage(size: Int, draw: (CGContext) -> Void) -> CGImage {
    let c = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    draw(c); return c.makeImage()!
}
func save(_ image: CGImage, to url: URL, quality: Double? = nil) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    try rep.representation(using: quality == nil ? .png : .jpeg, properties: quality.map { [.compressionFactor: $0] } ?? [:])!.write(to: url)
}
let icon = drawImage(size: 1024) { c in
    c.setFillColor(CGColor(red: 0.29, green: 0.41, blue: 0.30, alpha: 1)); c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    c.saveGState(); c.setShadow(offset: CGSize(width: 0, height: -25), blur: 60, color: CGColor(gray: 0, alpha: 0.22))
    c.setFillColor(CGColor(red: 0.91, green: 0.92, blue: 0.84, alpha: 1)); c.fillEllipse(in: CGRect(x: 205, y: 205, width: 614, height: 614)); c.restoreGState()
    c.addEllipse(in: CGRect(x: 205, y: 205, width: 614, height: 614)); c.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(red: 1, green: 0.99, blue: 0.95, alpha: 1), CGColor(red: 0.76, green: 0.81, blue: 0.71, alpha: 1)] as CFArray, locations: [0, 1])!
    c.drawRadialGradient(gradient, startCenter: CGPoint(x: 400, y: 650), startRadius: 10, endCenter: CGPoint(x: 500, y: 500), endRadius: 480, options: .drawsAfterEndLocation)
}
try save(icon, to: icons.appending(path: "Pearl.png"))
let mark = root.appending(path: "App/Assets.xcassets/PearlMark.imageset")
try FileManager.default.createDirectory(at: mark, withIntermediateDirectories: true)
try save(icon, to: mark.appending(path: "Pearl.png"))
try """
{"images":[{"filename":"Pearl.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}
""".write(to: mark.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
try """
{"images":[{"filename":"Pearl.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}
""".write(to: icons.appending(path: "Contents.json"), atomically: true, encoding: .utf8)

func landscape(_ variant: Int) -> CGImage {
    drawImage(size: 800) { c in
        let skies: [(CGFloat,CGFloat,CGFloat)] = [(0.60,0.78,0.86),(0.88,0.72,0.59),(0.64,0.71,0.57)]
        let sky = skies[variant % 3]
        c.setFillColor(CGColor(red: sky.0, green: sky.1, blue: sky.2, alpha: 1)); c.fill(CGRect(x:0,y:0,width:800,height:800))
        c.setFillColor(CGColor(red:0.96,green:0.94,blue:0.82,alpha:1)); c.fillEllipse(in:CGRect(x:540,y:570,width:100,height:100))
        c.setFillColor(CGColor(red:0.32,green:0.52,blue:0.57,alpha:1)); c.fill(CGRect(x:0,y:0,width:800,height:390))
        for i in 0..<16 {
            c.setStrokeColor(CGColor(gray:1,alpha:0.15)); c.setLineWidth(2)
            c.move(to:CGPoint(x:i*47,y:160+i*13)); c.addLine(to:CGPoint(x:160+i*47,y:160+i*13)); c.strokePath()
        }
        c.setFillColor(CGColor(red:0.31,green:0.39,blue:0.29,alpha:1))
        c.move(to:CGPoint(x:0,y:0)); c.addLine(to:CGPoint(x:0,y:540)); c.addLine(to:CGPoint(x:230,y:450)); c.addLine(to:CGPoint(x:340,y:250)); c.addLine(to:CGPoint(x:620,y:0)); c.closePath(); c.fillPath()
        c.setFillColor(CGColor(red:0.70,green:0.67,blue:0.46,alpha:1))
        c.move(to:CGPoint(x:90,y:0)); c.addLine(to:CGPoint(x:250,y:390)); c.addLine(to:CGPoint(x:275,y:380)); c.addLine(to:CGPoint(x:170,y:0)); c.closePath(); c.fillPath()
    }
}
for i in 0..<3 {
    let image = landscape(i)
    try save(image, to: fixtures.appending(path: "scene-\(i)-a.jpg"), quality: 0.95)
    try save(image, to: fixtures.appending(path: "scene-\(i)-b.jpg"), quality: 0.76)
}
try? FileManager.default.removeItem(at: fixtures.appending(path: "exact-copy.jpg"))
try FileManager.default.copyItem(at: fixtures.appending(path: "scene-0-a.jpg"), to: fixtures.appending(path: "exact-copy.jpg"))

// Synthetic clips exercise five-frame analysis without shipping personal media.
for variant in 0..<2 {
    let url = fixtures.appending(path: "clip-\(variant).mov")
    try? FileManager.default.removeItem(at: url)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 800, AVVideoHeightKey: 800,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: variant == 0 ? 800000 : 500000]])
    let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: 800, kCVPixelBufferHeightKey as String: 800])
    writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)
    for frame in 0..<30 {
        while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.01) }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adapter.pixelBufferPool!, &buffer)
        let pixel = buffer!; CVPixelBufferLockBaseAddress(pixel, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(pixel), width: 800, height: 800, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixel), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        context.draw(landscape(0), in: CGRect(x: 0, y: 0, width: 800, height: 800))
        context.setFillColor(CGColor(gray:1,alpha:0.5)); context.fillEllipse(in:CGRect(x:frame*12,y:320,width:30,height:8))
        CVPixelBufferUnlockBaseAddress(pixel, [])
        guard adapter.append(pixel, withPresentationTime: CMTime(value: Int64(frame), timescale: 10)) else { fatalError("Video fixture write failed") }
    }
    input.markAsFinished()
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting { semaphore.signal() }; semaphore.wait()
    guard writer.status == .completed else { fatalError("Video fixture finalize failed") }
}
