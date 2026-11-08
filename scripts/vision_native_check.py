"""Run the app's exact Vision helper code on the cloud Mac, without an iOS simulator."""
from pathlib import Path
import subprocess

source = Path('App/Services/Fingerprints.swift').read_text()
helpers = source.split('enum Fingerprints {', 1)[1].split('    static func perceptualHash', 1)[0]
swift = '''import Foundation
import Vision
import CoreGraphics
import CoreML
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
let a = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(image(false))))
let b = try Fingerprints.decode(Fingerprints.archive(Fingerprints.observation(image(true))))
let av = a.data.withUnsafeBytes { Array($0.bindMemory(to:Float.self)) }
let bv = b.data.withUnsafeBytes { Array($0.bindMemory(to:Float.self)) }
let l2 = sqrt(zip(av,bv).map { Double($0-$1)*Double($0-$1) }.reduce(0,+))
let distance = try Fingerprints.distance(a,b)
print("Native Mac Vision: sameData=\\(a.data==b.data), distance=\\(distance), manualL2=\\(l2), firstValues=\\(av.prefix(5))")
guard distance > 0.24 else { fatalError("Unrelated images failed the actual app matching threshold on native Mac") }
'''
Path('build').mkdir(exist_ok=True)
path = Path('build/vision-native.swift')
path.write_text(swift)
with Path('build/vision-native.log').open('w') as log:
    result = subprocess.run(['swift', str(path)], stdout=log, stderr=subprocess.STDOUT)
print(Path('build/vision-native.log').read_text())
raise SystemExit(result.returncode)
