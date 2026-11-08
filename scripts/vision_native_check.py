"""Run the app's exact Vision helper code on the cloud Mac, without an iOS simulator."""
from pathlib import Path
import subprocess

source = Path('App/Services/Fingerprints.swift').read_text()
helpers = source.split('enum Fingerprints {', 1)[1].split('    static func perceptualHash', 1)[0]
rules = Path('Sources/PearlCore/MatchRules.swift').read_text().split('public enum MatchRules {', 1)[1].split('    public static func similarVideo', 1)[0]
swift = '''import Foundation
import Vision
import CoreGraphics
import CoreML
import AppKit
import ImageIO
enum MatchRules {
''' + rules + '''
}
enum Fingerprints {
''' + helpers + '''
enum ScanError: Error { case unavailable }
}
func image(_ checker: Bool) -> CGImage {
    let c = CGContext(data:nil,width:512,height:512,bitsPerComponent:8,bytesPerRow:2048,
        space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.setFillColor(CGColor(red:0.2,green:0.7,blue:0.9,alpha:1)); c.fill(CGRect(x:0,y:0,width:512,height:512))
    if checker {
        for row in 0..<8 { for column in 0..<8 where (row+column)%2 == 0 {
            c.setFillColor(CGColor(gray:0,alpha:1));c.fill(CGRect(x:column*64,y:row*64,width:64,height:64))
        }}
    } else {
        c.setFillColor(CGColor(red:0.9,green:0.8,blue:0.2,alpha:1));c.fillEllipse(in:CGRect(x:350,y:50,width:80,height:80))
        c.setFillColor(CGColor(red:0.1,green:0.4,blue:0.2,alpha:1));c.fill(CGRect(x:0,y:0,width:512,height:230))
    }
    return c.makeImage()!
}
let original = image(false)
let jpeg = NSBitmapImageRep(cgImage: original).representation(using: .jpeg, properties: [.compressionFactor:0.55])!
let recompressed = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithData(jpeg as CFData,nil)!,0,nil)!
let a = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(original)))
let same = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(original)))
let compressed = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(recompressed)))
let b = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(image(true))))
let av = a.data.withUnsafeBytes { Array($0.bindMemory(to:Float.self)) }
let bv = b.data.withUnsafeBytes { Array($0.bindMemory(to:Float.self)) }
let l2 = sqrt(zip(av,bv).map { Double($0-$1)*Double($0-$1) }.reduce(0,+))
let distance = try Fingerprints.distance(a,b)
let identicalDistance = try Fingerprints.distance(a,same)
let compressedDistance = try Fingerprints.distance(a,compressed)
print("Native Mac Vision: identical=\\(identicalDistance), reencoded=\\(compressedDistance), unrelated=\\(distance), manualL2=\\(l2)")
guard MatchRules.similarPhoto([identicalDistance]), MatchRules.similarPhoto([compressedDistance]),
      !MatchRules.similarPhoto([distance]) else { fatalError("Native Vision failed the actual app matching rules") }
print("PASS: 3 native Vision accuracy cases using production helpers and matching rules")
'''
Path('build').mkdir(exist_ok=True)
path = Path('build/vision-native.swift')
path.write_text(swift)
with Path('build/vision-native.log').open('w') as log:
    result = subprocess.run(['swift', str(path)], stdout=log, stderr=subprocess.STDOUT)
print(Path('build/vision-native.log').read_text())
raise SystemExit(result.returncode)
